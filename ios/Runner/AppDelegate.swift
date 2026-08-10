import Flutter
import UIKit
import CoreBluetooth
import WidgetKit
import UserNotifications
import GoogleMaps

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - BackgroundSessionManager
// Manages a URLSession with background configuration for "Fire & Forget" uploads.
//
// The iOS system daemon (nsurlsessiond) owns the network task — the app can be
// suspended immediately after scheduling and the upload will still complete on
// a slow (0.15 Mbps) connection, preventing the 10-second watchdog from ever
// triggering and permanently throttling BLE background wakes.
// ─────────────────────────────────────────────────────────────────────────────
class BackgroundSessionManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    static let shared = BackgroundSessionManager()
    static let sessionIdentifier = "com.sipnudge.bg-upload"

    private var session: URLSession!
    private let lock = NSLock()

    /// Stored by AppDelegate when iOS calls handleEventsForBackgroundURLSession.
    /// Must be called after all background events are delivered so the OS knows
    /// we are done and can snapshot our app state.
    var backgroundCompletionHandler: (() -> Void)?

    /// taskIdentifier → temp file URL so we can delete the file after the upload.
    private var tempFiles: [Int: URL] = [:]

    /// taskIdentifier → (notificationURL, notificationBody) to fire the FCM push
    /// notification after the main upload succeeds.
    private var pendingNotifications: [Int: (url: URL, body: Data)] = [:]

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: BackgroundSessionManager.sessionIdentifier)
        // isDiscretionary = false → upload ASAP, not at OS discretion (e.g. while charging)
        config.isDiscretionary = false
        // sessionSendsLaunchEvents = true → CRITICAL: wakes the app when upload completes
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        NSLog("[BGSession] BackgroundSessionManager initialized — session: \(BackgroundSessionManager.sessionIdentifier)")
    }

    /// Schedule a background upload.
    /// Writes `body` to a temp file (background sessions require file-based uploads,
    /// not in-memory Data) and hands the task to nsurlsessiond.
    func scheduleUpload(url: URL,
                        method: String,
                        headers: [String: String],
                        body: Data,
                        notificationURL: URL? = nil,
                        notificationBody: Data? = nil) {
        _scheduleTask(url: url, method: method, headers: headers, body: body)

        // If a notification URL is provided, schedule it as a SEPARATE and SIMULTANEOUS
        // background task — NOT as a follow-up after the upload completes.
        // CRITICAL: URLSession.shared (foreground session) is suspended by iOS the moment
        // the app is backgrounded, so the old sequential approach (fire notification on
        // upload completion via URLSession.shared.dataTask) NEVER completes in background.
        // Scheduling both tasks via the background session hands them to nsurlsessiond,
        // which completes them independently even if the app is fully suspended.
        if let nURL = notificationURL, let nBody = notificationBody {
            NSLog("[BGSession] 📬 Scheduling notification task simultaneously with upload")
            _scheduleTask(url: nURL, method: "POST", headers: headers, body: nBody)
        }
    }

    /// Internal helper: writes body to a temp file and creates one background upload task.
    private func _scheduleTask(url: URL,
                               method: String,
                               headers: [String: String],
                               body: Data) {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".json")
        do {
            try body.write(to: tempFile)
        } catch {
            NSLog("[BGSession] ❌ Failed to write temp file: \(error.localizedDescription)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let task = session.uploadTask(with: request, fromFile: tempFile)
        lock.lock()
        tempFiles[task.taskIdentifier] = tempFile
        lock.unlock()

        task.resume()
        NSLog("[BGSession] 📤 Scheduled background task #\(task.taskIdentifier) → \(method) \(url.absoluteString)")
    }

    // ── URLSessionTaskDelegate ────────────────────────────────────────────────

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        // Always clean up the temp file regardless of success/failure
        var tempFile: URL? = nil
        lock.lock()
        tempFile = tempFiles.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        if let fileURL = tempFile {
            try? FileManager.default.removeItem(at: fileURL)
            NSLog("[BGSession] 🗑 Deleted temp file for task #\(task.taskIdentifier)")
        }

        if let error = error {
            NSLog("[BGSession] ❌ Task #\(task.taskIdentifier) failed: \(error.localizedDescription)")
            lock.lock()
            pendingNotifications.removeValue(forKey: task.taskIdentifier)
            lock.unlock()
            return
        }

        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        NSLog("[BGSession] ✅ Task #\(task.taskIdentifier) completed — HTTP \(statusCode)")

        // Pull the pending notification (if any) regardless of status code so we
        // don't accumulate stale entries if the upload fails.
        lock.lock()
        let pending = pendingNotifications.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        // NOTE: The notification task is now scheduled SIMULTANEOUSLY with the
        // upload in scheduleUploadWithNotification() below, so this block is kept
        // only as a safety-net in case legacy callers still pass a pending notification.
        // In practice, pending will always be nil with the new parallel approach.
        guard statusCode == 200, let p = pending else { return }

        // Fallback path (legacy): schedule via background session — NOT URLSession.shared,
        // which is a foreground session and gets suspended immediately in background.
        var notifRequest = URLRequest(url: p.url)
        notifRequest.httpMethod = "POST"
        notifRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        scheduleUpload(
            url: p.url,
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: p.body
        )
        NSLog("[BGSession] 📬 Notification task scheduled via background session (legacy path)")
        _ = notifRequest // suppress unused warning
    }

    // ── URLSessionDelegate ────────────────────────────────────────────────────

    /// Called by iOS when all background events for this session have been delivered.
    /// Calling the stored completion handler tells the OS we have finished processing
    /// and it may now take a snapshot of our app state and suspend us.
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        NSLog("[BGSession] All background events delivered — calling completion handler")
        DispatchQueue.main.async { [weak self] in
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}

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
        // Initialize Google Maps SDK immediately on iOS startup from Secrets.plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let mapsApiKey = dict["GoogleMapsAPIKey"] as? String, !mapsApiKey.isEmpty {
            GMSServices.provideAPIKey(mapsApiKey)
            NSLog("[AppDelegate] ✅ Google Maps API Key initialized from Secrets.plist")
        } else {
            NSLog("[AppDelegate] ⚠️ Secrets.plist or GoogleMapsAPIKey not found in bundle!")
        }

        // Register MethodChannel to receive Google Maps API Key dynamically from Dart
        if let controller = window?.rootViewController as? FlutterViewController {
            let mapsChannel = FlutterMethodChannel(name: "com.sipnudge.sipnudge/google_maps",
                                               binaryMessenger: controller.binaryMessenger)
            mapsChannel.setMethodCallHandler({
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                if call.method == "setApiKey",
                   let args = call.arguments as? [String: Any],
                   let key = args["key"] as? String {
                    GMSServices.provideAPIKey(key)
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            })

            // ── Native BLE MethodChannel ────────────────────────────────────────
            // Dart calls "triggerNativeConnect" immediately after flutter_blue_plus
            // connects so our native CBCentralManager gets the peripheral reference
            // via retrieveConnectedPeripherals. Without this, the native manager
            // may miss the peripheral on first launch and never register a pending
            // connection — causing iOS to never wake the app for BLE events.
            let bleChannel = FlutterMethodChannel(name: "com.sipnudge.sipnudge/native_ble",
                                                  binaryMessenger: controller.binaryMessenger)
            bleChannel.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "triggerNativeConnect" {
                    NSLog("[AppDelegate] triggerNativeConnect received from Dart")
                    if let self = self {
                        self.setupBleManager(controller: controller)
                        self.bleManager?.connectToSavedDevice()
                    }
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        // Register flutter plugins first
        GeneratedPluginRegistrant.register(with: self)

        // Touch BackgroundSessionManager early so its URLSession is registered
        // BEFORE iOS might deliver any pending background events on this launch.
        _ = BackgroundSessionManager.shared

        // Start the native BLE manager only if onboarding is completed and a device exists
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "flutter.onboarding_flow_completed")
        let hasDevice = UserDefaults.standard.string(forKey: "flutter.last_device_id") != nil
        
        if let controller = window?.rootViewController as? FlutterViewController {
            let nativeBleChannel = FlutterMethodChannel(
                name: "com.sipnudge.sipnudge/native_ble",
                binaryMessenger: controller.binaryMessenger
            )
            
            if onboardingCompleted && hasDevice {
                NSLog("[AppDelegate] Onboarding completed and device paired. Initializing SipnudgeBackgroundBLE on launch.")
                setupBleManager(controller: controller)
            } else {
                NSLog("[AppDelegate] Skipping native BLE manager initialization on launch (onboarding not completed or no device paired)")
            }
            
            // Emit the initial LPM state immediately so Flutter has the correct
            // value on first launch without waiting for a toggle event.
            let initialLPM = ProcessInfo.processInfo.isLowPowerModeEnabled
            NSLog("[AppDelegate] Initial LPM state → \(initialLPM)")
            DispatchQueue.main.async {
                nativeBleChannel.invokeMethod("onLowPowerModeChanged", arguments: initialLPM)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupBleManager(controller: FlutterViewController) {
        if bleManager == nil {
            NSLog("[AppDelegate] Instantiating SipnudgeBackgroundBLE")
            bleManager = SipnudgeBackgroundBLE()
            
            let nativeBleChannel = FlutterMethodChannel(
                name: "com.sipnudge.sipnudge/native_ble",
                binaryMessenger: controller.binaryMessenger
            )
            
            bleManager?.onNativeConnected = { uuid in
                DispatchQueue.main.async {
                    NSLog("[AppDelegate] onNativeConnected → notifying Dart uuid=\(uuid)")
                    nativeBleChannel.invokeMethod("onNativeConnected", arguments: uuid)
                }
            }
            
            bleManager?.onLowPowerModeChanged = { isActive in
                DispatchQueue.main.async {
                    NSLog("[AppDelegate] onLowPowerModeChanged → notifying Dart isActive=\(isActive)")
                    nativeBleChannel.invokeMethod("onLowPowerModeChanged", arguments: isActive)
                }
            }
        }
    }

    /// Called by iOS when background URL session events are ready to be delivered.
    /// We MUST store the completion handler and call it AFTER all events are processed
    /// (done inside BackgroundSessionManager.urlSessionDidFinishEvents).
    /// Failing to call this handler causes memory leaks and prevents iOS from
    /// taking a proper background snapshot.
    override func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        NSLog("[AppDelegate] handleEventsForBackgroundURLSession called: \(identifier)")
        if identifier == BackgroundSessionManager.sessionIdentifier {
            BackgroundSessionManager.shared.backgroundCompletionHandler = completionHandler
        } else {
            // Unknown session identifier — call immediately to avoid memory leak
            completionHandler()
        }
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
    /// DATA characteristic — sends real-time sip data including battery %
    private let kCharDataUUID      = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    private let kRestoreIdentifier = "com.sipnudge.background-ble"
    private let kAppGroupId        = "group.com.sipnudge.sipnudge"
    private let kPrefsDeviceKey    = "flutter.last_device_id"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var char30Days: CBCharacteristic?
    private var charAck: CBCharacteristic?
    private var charData: CBCharacteristic?

    /// Most-recently received battery percentage from the DATA characteristic.
    /// Included in the background upload so the server can track battery health.
    private var latestBatteryPercent: Int?

    /// True while the app is in the background — only process data then.
    private var inBackground = false

    /// Called whenever the native CBCentralManager successfully connects to the
    /// bottle. AppDelegate wires this to a MethodChannel event so the Dart/FBP
    /// side can also connect and update the UI — essential after a BT toggle
    /// where flutter_blue_plus's 30-second scan may have already timed out.
    var onNativeConnected: ((String) -> Void)?

    /// Called when iOS Low Power Mode is toggled ON or OFF.
    /// AppDelegate wires this to an 'onLowPowerModeChanged' MethodChannel call
    /// so Flutter can show a "Sync paused — Low Power Mode" banner.
    var onLowPowerModeChanged: ((Bool) -> Void)?

    private func log(_ msg: String) {
        print(msg)
        NSLog(msg)
    }

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
        log("[BG-BLE] Initialized with restore identifier: \(kRestoreIdentifier)")

        // ── Low Power Mode observer ───────────────────────────────────────────
        // NSProcessInfoPowerStateDidChangeNotification fires on the main thread
        // whenever the user toggles LPM in Settings → Battery.
        // We relay the new state to Flutter via MethodChannel so the UI can
        // show a "Sync paused" banner without polling.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLowPowerModeChange),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
        // Fire once on init so Flutter has the correct initial state immediately.
        let isLPM = ProcessInfo.processInfo.isLowPowerModeEnabled
        NSLog("[BG-BLE] Initial Low Power Mode state: \(isLPM)")
        // (Callback not yet wired — AppDelegate does that after init.)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Fired by NotificationCenter when iOS Low Power Mode is toggled.
    @objc private func handleLowPowerModeChange() {
        let isActive = ProcessInfo.processInfo.isLowPowerModeEnabled
        NSLog("[BG-BLE] Low Power Mode changed → isActive=\(isActive)")
        writeDebug("lpm", isActive ? "ON — uploads may be deferred" : "OFF — uploads resuming")
        
        if isActive {
            let content = UNMutableNotificationContent()
            content.title = "Low Power Mode Detected"
            content.body = "Background sync paused. Turn off Low Power Mode to resume background tracking."
            content.sound = .default
            let req = UNNotificationRequest(
                identifier: "lpm_detected",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
            NSLog("[BG-BLE] Low Power Mode local notification triggered")
        }
        
        onLowPowerModeChanged?(isActive)
    }

    private func writeDebug(_ key: String, _ value: String) {
        let d = UserDefaults(suiteName: kAppGroupId)
        let ts = Int(Date().timeIntervalSince1970)
        d?.set("[\(ts)] \(value)", forKey: "dbg_\(key)")
    }

    func enterBackground() {
        inBackground = true
        NSLog("[BG-BLE] Entered background — native manager active")
        // Always queue a connection if disconnected, even if BT is off.
        // CoreBluetooth will preserve this pending connection and attempt to
        // establish it as soon as Bluetooth is turned back on, waking our app.
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
        log("[BG-BLE] BT state: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            // BT came (back) on — re-establish connection to the bottle.
            connectToSavedDevice()
        case .poweredOff:
            // BT was turned off. Clear stale characteristic references so we
            // don't attempt ATT operations on a closed link. The pending
            // connect from didDisconnectPeripheral is also cancelled by the OS.
            // centralManagerDidUpdateState(.poweredOn) will call connectToSavedDevice()
            // when BT is re-enabled.
            char30Days = nil
            charAck = nil
            charData = nil
            log("[BG-BLE] BT powered off — cleared char refs, will reconnect when BT returns")
        default:
            break
        }
    }

    /// Called when iOS relaunches the app in the background for a BLE event.
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        log("[BG-BLE] willRestoreState called — restoring connections")

        // ── Path A: Restore peripherals from pending-connect list ─────────────
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for p in peripherals {
                log("[BG-BLE] Restored peripheral: \(p.identifier) state=\(p.state.rawValue)")
                peripheral = p
                peripheral?.delegate = self

                // Re-subscribe to characteristics that were already discovered
                for service in p.services ?? [] {
                    if service.uuid == kServiceUUID {
                        var char30DaysFound = false
                        var charAckFound = false
                        for char in service.characteristics ?? [] {
                            if char.uuid == kChar30DaysUUID {
                                char30Days = char
                                char30DaysFound = true
                                p.setNotifyValue(true, for: char)
                                log("[BG-BLE] willRestoreState: setNotifyValue(true) for 30-day char")
                            } else if char.uuid == kCharAckUUID {
                                charAck = char
                                charAckFound = true
                                log("[BG-BLE] willRestoreState: restored charAck")
                            } else if char.uuid == kCharDataUUID {
                                charData = char
                                p.setNotifyValue(true, for: char)
                                log("[BG-BLE] willRestoreState: setNotifyValue(true) for data char")
                            }
                        }
                        if !char30DaysFound || !charAckFound {
                            log("[BG-BLE] willRestoreState: service found but chars missing — discovering characteristics")
                            p.discoverCharacteristics([kChar30DaysUUID, kCharAckUUID, kCharDataUUID], for: service)
                        }
                    }
                }

                // Always call connect to register our app's connection reference.
                // This ensures we get centralManager(_:didConnect:) if it is already system-connected,
                // or establishes a pending connection if it is disconnected.
                log("[BG-BLE] willRestoreState: issuing connect for restored peripheral \(p.identifier)")
                central.connect(p, options: nil)
            }
        }

        // ── Path B: Restore active scan (second independent relaunch trigger) ──
        // iOS can also restore an in-progress scan. Re-issuing scanForPeripherals
        // here registers a SECOND background-wake path — if the pending connect
        // is not sufficient (e.g. bottle not yet advertising), the OS can still
        // relaunch us when it sees our service UUID in an advertisement.
        if let scanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID],
           !scanServices.isEmpty {
            log("[BG-BLE] willRestoreState: restoring scan for services: \(scanServices.map { $0.uuidString })")
            central.scanForPeripherals(withServices: [kServiceUUID], options: nil)
        } else {
            // Even if there was no prior scan to restore, proactively start one.
            // Two conditions must both be met for the OS to wake us:
            //   1. A pending connect() call — already issued above.
            //   2. The peripheral is advertising. If it stopped advertising,
            //      the scan path catches the next advertisement window.
            log("[BG-BLE] willRestoreState: no prior scan to restore — starting proactive scan")
            central.scanForPeripherals(withServices: [kServiceUUID], options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("[BG-BLE] Connected to \(peripheral.identifier)")
        writeDebug("connected", "connected to \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices([kServiceUUID])
        // Notify the Dart side so flutter_blue_plus can also connect and the
        // Flutter UI reflects the connection — critical after BT toggle or when
        // the 30-second FBP scan has already timed out.
        onNativeConnected?(peripheral.identifier.uuidString)
    }

    func centralManager(_ central: CBCentralManager,
                         didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("[BG-BLE] Disconnected from \(peripheral.identifier)")
        self.char30Days = nil
        self.charData = nil
        // Always queue a reconnect immediately.
        // CoreBluetooth queues connection requests even when state is .poweredOff,
        // so that when Bluetooth transitions back to .poweredOn, the connection
        // is automatically retried. If we skipped this while BT was off, we would
        // have no pending connection when BT comes back on, meaning iOS would
        // never wake our suspended app in the background.
        NSLog("[BG-BLE] Registering pending connect for next bottle advertisement")
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                         didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("[BG-BLE] Failed to connect — error: \(error?.localizedDescription ?? "none")")
        central.connect(peripheral, options: nil)
    }

    // ── CBPeripheralDelegate ─────────────────────────────────────────────────

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            NSLog("[BG-BLE] discoverServices error: \(error!)")
            return
        }
        for service in peripheral.services ?? [] {
            if service.uuid == kServiceUUID {
                peripheral.discoverCharacteristics([kChar30DaysUUID, kCharAckUUID, kCharDataUUID], for: service)
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
            } else if char.uuid == kCharDataUUID {
                charData = char
                // Subscribe so we get real-time battery updates in the background.
                peripheral.setNotifyValue(true, for: char)
                NSLog("[BG-BLE] setNotifyValue(true) called for data char (battery source)")
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
    ///
    /// CRITICAL "Fire & Forget" pattern:
    ///   A. Begin a background task so iOS doesn't kill us while we pack data.
    ///   B. Parse the payload and update the App Group (WidgetKit).
    ///   C. Hand the network upload to BackgroundSessionManager (nsurlsessiond).
    ///   D. Call endBackgroundTask IMMEDIATELY — the app returns to sleep in <0.1s.
    ///   → The 10-second watchdog is NEVER triggered regardless of network speed.
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        // ── A: Begin background task ──────────────────────────────────────────
        var bgTaskId = UIBackgroundTaskIdentifier.invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "SipnudgeBLEProcess") {
            // Expiry handler: called only if we somehow exceed the allowed time.
            // End immediately to avoid a hard force-kill. Should never happen with
            // Fire & Forget because endBackgroundTask is called in <0.1 seconds below.
            NSLog("[BG-BLE] ⚠️ Background task expiry handler triggered — ending task defensively")
            UIApplication.shared.endBackgroundTask(bgTaskId)
            bgTaskId = .invalid
        }

        // ── Handle DATA characteristic (battery percentage) ───────────────────
        if characteristic.uuid == kCharDataUUID,
           let data = characteristic.value,
           let payload = String(data: data, encoding: .utf8) {
            // Parse semicolon-delimited key=value pairs: "battery=75;volume=450;..."
            for pair in payload.components(separatedBy: ";") {
                let kv = pair.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "=")
                if kv.count == 2, kv[0].trimmingCharacters(in: .whitespaces) == "battery",
                   let pct = Int(kv[1].trimmingCharacters(in: .whitespaces)) {
                    latestBatteryPercent = pct
                    NSLog("[BG-BLE] Updated latestBatteryPercent = \(pct)%")
                    break
                }
            }
            UIApplication.shared.endBackgroundTask(bgTaskId)
            bgTaskId = .invalid
            return
        }

        // ── Validate 30-day data ──────────────────────────────────────────────
        guard error == nil,
              characteristic.uuid == kChar30DaysUUID,
              let data = characteristic.value,
              let payload = String(data: data, encoding: .utf8) else {
            if let e = error { writeDebug("ble_rx", "ERROR: \(e.localizedDescription)") }
            UIApplication.shared.endBackgroundTask(bgTaskId)
            bgTaskId = .invalid
            return
        }

        writeDebug("ble_rx", "got data len=\(data.count) bg=\(inBackground)")
        NSLog("[BG-BLE] Received 30-day payload (inBackground=\(inBackground)): \(payload.prefix(80))…")

        // ── Debug notification: visible on lock screen without Xcode ──────────
        // This fires IMMEDIATELY when BLE data arrives in background, proving
        // the OS wake-up is working. Remove once background sync is confirmed.
        // if inBackground {
        //     let dbgContent = UNMutableNotificationContent()
        //     dbgContent.title = "📶 BG BLE Data Received"
        //     dbgContent.body = "Native background sync triggered. Uploading \(data.count) bytes..."
        //     dbgContent.sound = .default
        //     let dbgReq = UNNotificationRequest(
        //         identifier: "bg_ble_rx_\(Int(Date().timeIntervalSince1970))",
        //         content: dbgContent,
        //         trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        //     )
        //     UNUserNotificationCenter.current().add(dbgReq, withCompletionHandler: nil)
        //     NSLog("[BG-BLE] Debug notification scheduled")
        // }

        // ── B: Parse today's consumed value ───────────────────────────────────
        var todayConsumed = 0
        var todayDate = Calendar.current.startOfDay(for: Date())
        var todayDayIndex = 0

        // Strip ALL invisible characters (\r, \n, null bytes, etc.) from the full payload
        // before splitting. BLE payloads from some firmware revisions include \r\n line
        // endings that survive a simple .whitespaces trim on individual segments and cause
        // Double()/Int() to return nil — leaving todayConsumed at 0 and firing a "0ml" notification.
        let cleanPayload = payload
            .components(separatedBy: .controlCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = cleanPayload.components(separatedBy: "|")

        if parts.count >= 2,
           let epochStr = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           !epochStr.isEmpty,
           let epochNum = Int(epochStr) {

            let epochMs = epochStr.count == 13 ? epochNum : epochNum * 1000
            let startDate = Date(timeIntervalSince1970: Double(epochMs) / 1000.0)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            var latestDayIndex = -1
            var latestConsumed = 0

            for seg in parts.dropFirst() {
                // Aggressively strip any remaining control/whitespace characters from each segment
                let s = seg
                    .components(separatedBy: .controlCharacters)
                    .joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !s.isEmpty, s.lowercased() != "na" else { continue }

                let segParts = s.components(separatedBy: "/")
                guard segParts.count >= 3 else { continue }

                let rawDay = segParts[0]
                    .components(separatedBy: .controlCharacters).joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let rawConsumed = segParts[2]
                    .components(separatedBy: .controlCharacters).joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard let dayIndex = Int(rawDay),
                      let consumed = Double(rawConsumed) else {
                    NSLog("[BG-BLE] ⚠️ Skipping malformed segment: '\(s)' (rawDay='\(rawDay)' rawConsumed='\(rawConsumed)')")
                    continue
                }

                if dayIndex > latestDayIndex {
                    latestDayIndex = dayIndex
                    // Only count days that have actual consumption — day 29 (and most
                    // future slots) will have consumed=0, making the fallback useless
                    // if we naively track the last dayIndex regardless of its value.
                    if Int(consumed) > 0 {
                        latestConsumed = Int(consumed)
                    }
                }

                let segDate = calendar.startOfDay(for: startDate.addingTimeInterval(Double(dayIndex) * 86400))
                if segDate == today {
                    todayConsumed = Int(consumed)
                    todayDate = segDate
                    todayDayIndex = dayIndex
                    NSLog("[BG-BLE] ✅ Today's segment matched: dayIndex=\(dayIndex) consumed=\(consumed)ml")
                    break
                }
            }

            if todayConsumed == 0 && latestConsumed > 0 {
                NSLog("[BG-BLE] ⚠️ No exact today match — falling back to latest segment: dayIndex=\(latestDayIndex) consumed=\(latestConsumed)ml")
                todayConsumed = latestConsumed
                todayDate = calendar.startOfDay(for: startDate.addingTimeInterval(Double(latestDayIndex) * 86400))
                todayDayIndex = latestDayIndex
            }
        }

        // ── Update shared App Group UserDefaults → WidgetKit refreshes instantly ──
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

        // ── C: Schedule background upload — Fire & Forget ─────────────────────
        // Hand the network task to the iOS background daemon (nsurlsessiond).
        // It will complete the upload independently, even on a 0.15 Mbps connection,
        // even if the app is fully suspended after step D below.
        //
        // IMPORTANT: Only send a push notification when consumed > 0.
        // The bottle fires BLE notifications on every lid-open, including early
        // morning before the user has had their first sip, resulting in a
        // misleading "You have consumed 0ml so far today." notification.
        uploadTodayDataViaBackgroundSession(
            consumed: Double(todayConsumed),
            date: todayDate,
            dayIndex: todayDayIndex,
            deviceId: peripheral.identifier.uuidString,
            sendNotification: todayConsumed > 0,
            battery: latestBatteryPercent
        )

        // ── D: End background task IMMEDIATELY ────────────────────────────────
        // The upload is now owned by nsurlsessiond. Signal iOS we are done so the
        // app goes back to sleep — well under the 10-second watchdog limit.
        UIApplication.shared.endBackgroundTask(bgTaskId)
        bgTaskId = .invalid
        NSLog("[BG-BLE] ✅ Background task ended — app returning to sleep")
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private func uploadTodayDataViaBackgroundSession(
        consumed: Double,
        date: Date,
        dayIndex: Int,
        deviceId: String,
        sendNotification: Bool,
        battery: Int? = nil
    ) {
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

        var body: [String: Any] = [
            "userId": userId,
            "date": dateStr,
            "consumed": consumed,
            "target": goal,
            "dayIndex": dayIndex,
            "deviceId": deviceId,
            "isPerfect": isPerfect,
            "sendNotification": sendNotification
        ]
        if let batteryPct = battery {
            body["battery"] = batteryPct
        }

        guard let uploadURL = URL(string: "https://api.sipnudge.com/api/database/update-today-consumed-with-notification") else {
            NSLog("[BG-BLE] ❌ Invalid URL")
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

            NSLog("[BG-BLE] 📤 Scheduling background upload for user \(userId) (consumed: \(consumed)ml, target: \(goal)ml, notify: \(sendNotification))")
            writeDebug("api_tx", "scheduling bg upload \(consumed)ml notify=\(sendNotification)")

            BackgroundSessionManager.shared.scheduleUpload(
                url: uploadURL,
                method: "PATCH",
                headers: ["Content-Type": "application/json"],
                body: jsonData
            )
        } catch {
            NSLog("[BG-BLE] ❌ JSON serialization error: \(error.localizedDescription)")
            writeDebug("api_tx", "JSON_ERR")
        }
    }

    /// Internal (not private) so AppDelegate can trigger it via MethodChannel.
    func connectToSavedDevice() {
        if let p = peripheral, p.state == .connected, char30Days != nil {
            log("[BG-BLE] Already connected and subscribed — skipping redundant connect")
            return
        }

        let rawUUIDStr = UserDefaults.standard.string(forKey: kPrefsDeviceKey)
        log("[BG-BLE] Saved device UUID from prefs (key=\(kPrefsDeviceKey)): \(rawUUIDStr ?? "NIL")")
        writeDebug("uuid", rawUUIDStr ?? "NIL")

        guard let uuidStr = rawUUIDStr,
              let uuid = UUID(uuidString: uuidStr) else {
            log("[BG-BLE] No saved device UUID — waiting for flutter_blue_plus to pair")
            return
        }

        // 1. Try known peripherals (fastest — already in CoreBluetooth cache)
        let known = central.retrievePeripherals(withIdentifiers: [uuid])
        if let p = known.first {
            log("[BG-BLE] Found saved peripheral in cache — connecting")
            peripheral = p
            peripheral?.delegate = self
            central.connect(p, options: nil)
            return
        }

        // 2. Fallback: already connected to the system (e.g. flutter_blue_plus owns it)
        let connected = central.retrieveConnectedPeripherals(withServices: [kServiceUUID])
        if let p = connected.first(where: { $0.identifier == uuid }) {
            log("[BG-BLE] Peripheral already connected to system — registering with our manager")
            peripheral = p
            peripheral?.delegate = self
            central.connect(p, options: nil) // Establish our own manager's connection entry
            return
        }

        log("[BG-BLE] Peripheral \(uuid) not in cache yet — will connect after flutter_blue_plus pairs")
    }

    private func updateWidget(from payload: String) {
        // Disabled widget updates here to avoid local state interference.
        // The background BLE sync now uploads today's consumed value directly to the API.
        // The Flutter app will fetch this data upon startup or resume.
        log("[BG-BLE] updateWidget called (disabled - uploading directly to API instead)")
    }
}
