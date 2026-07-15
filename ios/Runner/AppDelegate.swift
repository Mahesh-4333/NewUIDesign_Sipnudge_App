import Flutter
import UIKit
import CoreBluetooth
import WidgetKit
import UserNotifications

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AppDelegate
// ─────────────────────────────────────────────────────────────────────────────
@main
@objc class AppDelegate: FlutterAppDelegate {

    /// Shared native BLE manager — stays connected in the background
    private var bleManager: SipnudgeBackgroundBLE?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register flutter plugins first
        GeneratedPluginRegistrant.register(with: self)

        // Start the native BLE manager (connects immediately, stays connected)
        bleManager = SipnudgeBackgroundBLE()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Required for CoreBluetooth state restoration when the OS relaunches the app
    override func application(
        _ application: UIApplication,
        shouldSaveSecureApplicationState coder: NSCoder
    ) -> Bool { true }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        bleManager?.enterBackground()
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        bleManager?.enterForeground()
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        let content = UNMutableNotificationContent()
        content.title = "Sipnudge is closed"
        content.body = "Background sync paused. Reopen the app to resume."
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "app_terminated",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SipnudgeBackgroundBLE
// Native CBCentralManager with state restoration.
// This is the ONLY manager registered for background BLE wakeups, so iOS
// reliably wakes the app and calls our delegate even in Release mode.
// ─────────────────────────────────────────────────────────────────────────────
class SipnudgeBackgroundBLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // BLE UUIDs — must match the Dart BLE cubit exactly
    private let kServiceUUID       = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let kChar30DaysUUID    = CBUUID(string: "6E400006-B5A3-F393-E0A9-E50E24DCCA9E")
    private let kCharAckUUID       = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let kRestoreIdentifier = "com.sipnudge.background-ble"
    private let kAppGroupId        = "group.com.sipnudge.sipnudge"
    private let kPrefsDeviceKey    = "flutter.last_device_id"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var char30Days: CBCharacteristic?
    private var charAck: CBCharacteristic?

    /// True while the app is in the background — only process data then.
    private var inBackground = false

    override init() {
        super.init()
        // CBCentralManagerOptionRestoreIdentifierKey is THE key that tells iOS
        // to keep this manager alive after app suspension and call
        // centralManager(_:willRestoreState:) when a BLE event arrives.
        central = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.sipnudge.ble-background", qos: .background),
            options: [
                CBCentralManagerOptionRestoreIdentifierKey: kRestoreIdentifier,
                CBCentralManagerOptionShowPowerAlertKey: false
            ]
        )
        NSLog("[BG-BLE] Initialized with restore identifier: \(kRestoreIdentifier)")
    }

    private func writeDebug(_ key: String, _ value: String) {
        let d = UserDefaults(suiteName: kAppGroupId)
        let ts = Int(Date().timeIntervalSince1970)
        d?.set("[\(ts)] \(value)", forKey: "dbg_\(key)")
    }

    func enterBackground() {
        inBackground = true
        NSLog("[BG-BLE] Entered background — native manager active")
        // Re-connect if somehow disconnected when going to background
        if let p = peripheral, p.state != .connected {
            central.connect(p, options: nil)
        } else if peripheral == nil {
            connectToSavedDevice()
        }
    }

    func enterForeground() {
        inBackground = false
        NSLog("[BG-BLE] Entered foreground — native manager standing by")
    }

    // ── CBCentralManagerDelegate ──────────────────────────────────────────────

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("[BG-BLE] BT state: \(central.state.rawValue)")
        if central.state == .poweredOn {
            connectToSavedDevice()
        }
    }

    /// Called when iOS relaunches the app in the background for a BLE event.
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        NSLog("[BG-BLE] willRestoreState called — restoring connections")
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for p in peripherals {
                NSLog("[BG-BLE] Restored peripheral: \(p.identifier)")
                peripheral = p
                peripheral?.delegate = self
                // Re-subscribe to the 30-day characteristic if it was already discovered
                for service in p.services ?? [] {
                    for char in service.characteristics ?? [] {
                        if char.uuid == kChar30DaysUUID {
                            char30Days = char
                            // Always force subscription — same reason as didDiscoverCharacteristicsFor
                            p.setNotifyValue(true, for: char)
                            NSLog("[BG-BLE] willRestoreState: setNotifyValue(true) for 30-day char")
                        } else if char.uuid == kCharAckUUID {
                            charAck = char
                            NSLog("[BG-BLE] willRestoreState: restored charAck")
                        }
                    }
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("[BG-BLE] Connected to \(peripheral.identifier)")
        writeDebug("connected", "connected to \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices([kServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                         didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("[BG-BLE] Disconnected from \(peripheral.identifier) — reconnecting")
        self.char30Days = nil
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                         didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("[BG-BLE] Failed to connect — retrying in 3s")
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.central.connect(peripheral, options: nil)
        }
    }

    // ── CBPeripheralDelegate ─────────────────────────────────────────────────

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            NSLog("[BG-BLE] discoverServices error: \(error!)")
            return
        }
        for service in peripheral.services ?? [] {
            if service.uuid == kServiceUUID {
                peripheral.discoverCharacteristics([kChar30DaysUUID, kCharAckUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            NSLog("[BG-BLE] discoverCharacteristics error: \(error!)")
            return
        }
        for char in service.characteristics ?? [] {
            if char.uuid == kChar30DaysUUID {
                char30Days = char
                // Always call setNotifyValue(true) — even if isNotifying appears true.
                // If flutter_blue_plus already set the CCCD, iOS reports isNotifying=true
                // on our proxy too, causing us to skip subscription. Forcing it ensures
                // our CBCentralManager session is registered as a subscriber independently.
                peripheral.setNotifyValue(true, for: char)
                NSLog("[BG-BLE] setNotifyValue(true) called for 30-day char (isNotifying=\(char.isNotifying))")
            } else if char.uuid == kCharAckUUID {
                charAck = char
                NSLog("[BG-BLE] Found ACK characteristic")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let e = error {
            NSLog("[BG-BLE] setNotifyValue error: \(e)")
            writeDebug("subscribed", "ERROR: \(e.localizedDescription)")
        } else {
            NSLog("[BG-BLE] Notification state → \(characteristic.isNotifying) for \(characteristic.uuid)")
            writeDebug("subscribed", "isNotifying=\(characteristic.isNotifying)")
        }
    }

    /// Called when the bottle pushes a BLE notification — this fires even when
    /// the app is suspended in Release mode, as long as:
    ///   1. bluetooth-central is in UIBackgroundModes  ✅
    ///   2. CBCentralManagerOptionRestoreIdentifierKey is set  ✅
    ///   3. setNotifyValue(true) succeeded  ✅
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil,
              characteristic.uuid == kChar30DaysUUID,
              let data = characteristic.value,
              let payload = String(data: data, encoding: .utf8) else {
            if let e = error { writeDebug("ble_rx", "ERROR: \(e.localizedDescription)") }
            return
        }

        writeDebug("ble_rx", "got data len=\(data.count) bg=\(inBackground)")
        NSLog("[BG-BLE] Received 30-day payload (inBackground=\(inBackground)): \(payload.prefix(80))…")
        
        // Parse today's consumed value and upload directly to API
        var todayConsumed = 0
        var todayDate = Calendar.current.startOfDay(for: Date())
        var todayDayIndex = 0
        
        let parts = payload
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "|")
            
        if parts.count >= 2,
           let epochStr = parts.first?.trimmingCharacters(in: .whitespaces),
           let epochNum = Int(epochStr) {
            
            let epochMs = epochStr.count == 13 ? epochNum : epochNum * 1000
            let startDate = Date(timeIntervalSince1970: Double(epochMs) / 1000.0)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            var latestDayIndex = -1
            var latestConsumed = 0
            
            for seg in parts.dropFirst() {
                let s = seg.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !s.isEmpty, s.lowercased() != "na" else { continue }
                
                let segParts = s.components(separatedBy: "/")
                guard segParts.count >= 3,
                      let dayIndex = Int(segParts[0].trimmingCharacters(in: .whitespaces)),
                      let consumed = Double(segParts[2].trimmingCharacters(in: .whitespaces)) else {
                    continue
                }
                
                if dayIndex > latestDayIndex {
                    latestDayIndex = dayIndex
                    latestConsumed = Int(consumed)
                }
                
                let segDate = calendar.startOfDay(for: startDate.addingTimeInterval(Double(dayIndex) * 86400))
                if segDate == today {
                    todayConsumed = Int(consumed)
                    todayDate = segDate
                    todayDayIndex = dayIndex
                    break
                }
            }
            
            if todayConsumed == 0 && latestConsumed > 0 {
                todayConsumed = latestConsumed
                todayDate = calendar.startOfDay(for: startDate.addingTimeInterval(Double(latestDayIndex) * 86400))
                todayDayIndex = latestDayIndex
            }
        }
        
        // Update shared App Group UserDefaults so the native Widget can refresh instantly in the background
        if let appDefaults = UserDefaults(suiteName: kAppGroupId) {
            let storedGoal = UserDefaults.standard.object(forKey: "flutter.water_goal") as? Int
                ?? appDefaults.object(forKey: "daily_goal") as? Int
                ?? 2500
            let goal = storedGoal > 0 ? storedGoal : 2500

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = .current
            let todayStr = formatter.string(from: Date())

            if todayConsumed > 0 {
                let lastUpdateDateStr = appDefaults.string(forKey: "last_update_date") ?? ""
                var existingIntake = appDefaults.integer(forKey: "current_intake")
                if lastUpdateDateStr != todayStr {
                    existingIntake = 0
                }
                
                if todayConsumed > existingIntake {
                    appDefaults.set(todayConsumed, forKey: "current_intake")
                    NSLog("[BG-BLE] Natively updated App Group current_intake to \(todayConsumed)")
                }
            }
            appDefaults.set(goal, forKey: "daily_goal")
            appDefaults.set(todayStr, forKey: "last_update_date")
            appDefaults.synchronize()
            
            DispatchQueue.main.async {
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                    NSLog("[BG-BLE] Triggered reloadAllTimelines() for native widget")
                }
            }
        }
        
        // Directly upload on data API
        uploadTodayDataToAPI(consumed: Double(todayConsumed), date: todayDate, dayIndex: todayDayIndex, deviceId: peripheral.identifier.uuidString)

        // Send ACK back to the bottle so its LED turns off/closes sync session
        // if let ackChar = charAck {
        //     let ackData = "ACK".data(using: .utf8)!
        //     peripheral.writeValue(ackData, for: ackChar, type: .withoutResponse)
        //     NSLog("[BG-BLE] Sent ACK to bottle inside didUpdateValueFor")
        //     writeDebug("ble_tx", "sent ACK")
        // } else {
        //     NSLog("[BG-BLE] Warning: ACK char not discovered yet, cannot send ACK")
        // }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private func uploadTodayDataToAPI(consumed: Double, date: Date, dayIndex: Int, deviceId: String) {
        guard let userId = UserDefaults.standard.string(forKey: "flutter.user_id")
                ?? UserDefaults(suiteName: kAppGroupId)?.string(forKey: "flutter.user_id")
                ?? UserDefaults.standard.string(forKey: "user_id")
                ?? UserDefaults(suiteName: kAppGroupId)?.string(forKey: "user_id") else {
            NSLog("[BG-BLE] ❌ Cannot upload payload: No userId found")
            writeDebug("api_tx", "FAIL: No userId")
            return
        }

        let storedGoal = UserDefaults.standard.object(forKey: "flutter.water_goal") as? Int
            ?? UserDefaults(suiteName: kAppGroupId)?.object(forKey: "daily_goal") as? Int
            ?? 2500
        let goal = storedGoal > 0 ? storedGoal : 2500

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let todayStr = formatter.string(from: Date())
        let dateStr = "\(todayStr)T00:00:00.000Z"

        let isPerfect = consumed >= Double(goal)

        let body: [String: Any] = [
            "userId": userId,
            "date": dateStr,
            "consumed": consumed,
            "target": goal,
            "dayIndex": dayIndex,
            "deviceId": deviceId,
            "isPerfect": isPerfect
        ]

        guard let url = URL(string: "https://api.sipnudge.com/api/database/update-today-consumed") else {
            NSLog("[BG-BLE] ❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData

            NSLog("[BG-BLE] 📤 Uploading today's data for user \(userId) (consumed: \(consumed)ml, target: \(goal)ml) to API...")
            writeDebug("api_tx", "sending \(consumed)ml")

            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    NSLog("[BG-BLE] ❌ API Upload error: \(error.localizedDescription)")
                    self?.writeDebug("api_tx", "ERROR: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    NSLog("[BG-BLE] 📥 API Response code: \(httpResponse.statusCode)")
                    self?.writeDebug("api_tx", "HTTP \(httpResponse.statusCode)")
                }
            }
            task.resume()
        } catch {
            NSLog("[BG-BLE] ❌ JSON serialization error: \(error.localizedDescription)")
            writeDebug("api_tx", "JSON_ERR")
        }
    }

    private func connectToSavedDevice() {
        let rawUUIDStr = UserDefaults.standard.string(forKey: kPrefsDeviceKey)
        NSLog("[BG-BLE] Saved device UUID from prefs (key=\(kPrefsDeviceKey)): \(rawUUIDStr ?? "NIL")")
        writeDebug("uuid", rawUUIDStr ?? "NIL")

        guard let uuidStr = rawUUIDStr,
              let uuid = UUID(uuidString: uuidStr) else {
            NSLog("[BG-BLE] No saved device UUID — waiting for flutter_blue_plus to pair")
            return
        }

        // 1. Try known peripherals (fastest — already in CoreBluetooth cache)
        let known = central.retrievePeripherals(withIdentifiers: [uuid])
        if let p = known.first {
            NSLog("[BG-BLE] Found saved peripheral in cache — connecting")
            peripheral = p
            peripheral?.delegate = self
            central.connect(p, options: nil)
            return
        }

        // 2. Fallback: already connected to the system (e.g. flutter_blue_plus owns it)
        let connected = central.retrieveConnectedPeripherals(withServices: [kServiceUUID])
        if let p = connected.first(where: { $0.identifier == uuid }) {
            NSLog("[BG-BLE] Peripheral already connected to system — registering with our manager")
            peripheral = p
            peripheral?.delegate = self
            central.connect(p, options: nil) // Establish our own manager's connection entry
            return
        }

        NSLog("[BG-BLE] Peripheral \(uuid) not in cache yet — will connect after flutter_blue_plus pairs")
    }

    private func updateWidget(from payload: String) {
        // Disabled widget updates here to avoid local state interference.
        // The background BLE sync now uploads today's consumed value directly to the API.
        // The Flutter app will fetch this data upon startup or resume.
        NSLog("[BG-BLE] updateWidget called (disabled - uploading directly to API instead)")
    }
}
