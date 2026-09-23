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

        // Set UNUserNotificationCenter delegate to self for sound & alert handling on iOS
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
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

    // override func applicationWillTerminate(_ application: UIApplication) {
    //     super.applicationWillTerminate(application)

    //     let hasDevice = UserDefaults.standard.string(forKey: "flutter.last_device_id") != nil
    //     let onboardingCompleted = UserDefaults.standard.bool(forKey: "flutter.onboarding_flow_completed")

    //     // 6-hour cooldown (21,600s) to avoid spamming the user during repeated background OS kills / app switches
    //     let lastNotifTime = UserDefaults.standard.double(forKey: "last_termination_notif_time")
    //     let now = Date().timeIntervalSince1970
    //     let cooldownSeconds: Double = 6 * 3600

    //     if (hasDevice || onboardingCompleted) && (now - lastNotifTime >= cooldownSeconds) {
    //         UserDefaults.standard.set(now, forKey: "last_termination_notif_time")

    //         let content = UNMutableNotificationContent()
    //         content.title = "Background Sync Paused"
    //         content.body = "Sipnudge was closed. Keep the app open in the background to continue automatic water tracking."
    //         content.sound = .default
    //         let req = UNNotificationRequest(
    //             identifier: "app_terminated_sync_paused",
    //             content: content,
    //             trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    //         )
    //         let semaphore = DispatchSemaphore(value: 0)
    //         UNUserNotificationCenter.current().add(req) { error in
    //             if let error = error {
    //                 NSLog("[AppDelegate] Failed to schedule termination notification: \(error.localizedDescription)")
    //             } else {
    //                 NSLog("[AppDelegate] Successfully scheduled termination notification")
    //             }
    //             semaphore.signal()
    //         }
    //         _ = semaphore.wait(timeout: .now() + 1.0)
    //     }
    // }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
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
    /// DATA characteristic — sends real-time sip data including battery % and daily_total_ml
    private let kCharDataUUID      = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    /// CONSUMED UPDATE characteristic — write manual liquid delta to bottle firmware
    private let kConsumedUpdateUUID = CBUUID(string: "6E40000A-B5A3-F393-E0A9-E50E24DCCA9E")
    private let kRestoreIdentifier = "com.sipnudge.background-ble"
    private let kAppGroupId        = "group.com.sipnudge.sipnudge"
    private let kPrefsDeviceKey    = "flutter.last_device_id"

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var charData: CBCharacteristic?
    private var consumedUpdateChar: CBCharacteristic?

    /// Most-recently received battery percentage from the DATA characteristic.
    /// Included in the background upload so the server can track battery health.
    private var latestBatteryPercent: Int?

    /// True while the app is in the background — only process data then.
    private var inBackground = false

    /// Debounce tracker to prevent duplicate background uploads when BLE fires multiple packets
    private var lastUploadedConsumed: Int?
    private var lastUploadTime: Date?

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
            let lastLpmNotifTime = UserDefaults.standard.double(forKey: "last_lpm_notif_time")
            let now = Date().timeIntervalSince1970
            let cooldownSeconds: Double = 6 * 3600 // 6 hours

            if now - lastLpmNotifTime >= cooldownSeconds {
                UserDefaults.standard.set(now, forKey: "last_lpm_notif_time")

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
        }
        
        onLowPowerModeChanged?(isActive)
    }

    private func writeDebug(_ key: String, _ value: String) {
        let d = UserDefaults(suiteName: kAppGroupId)
        let ts = Int(Date().timeIntervalSince1970)
        d?.set("[\(ts)] \(value)", forKey: "dbg_\(key)")
    }

    /// Sends any accumulated manual liquid delta (from widget logs) to BLE characteristic 000A.
    /// Called after services are discovered and when the app enters foreground.
    func syncPendingManualDelta() {
        guard let char = consumedUpdateChar,
              let p = peripheral, p.state == .connected else {
            return
        }

        let appDefaults = UserDefaults(suiteName: kAppGroupId)
        let pendingDelta = appDefaults?.integer(forKey: "pending_manual_liquid_delta") ?? 0

        guard pendingDelta != 0 else { return }

        var payload: String
        if pendingDelta > 0 {
            payload = "+\(pendingDelta)"
        } else {
            payload = "\(pendingDelta)"
        }

        NSLog("[BG-BLE] Writing manual liquid delta (000A): \(payload)")
        let data = payload.data(using: .utf8) ?? Data()
        p.writeValue(data, for: char, type: .withoutResponse)

        appDefaults?.set(0, forKey: "pending_manual_liquid_delta")
        appDefaults?.synchronize()
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
        // Sync any pending manual delta from widget logs when app comes to foreground
        syncPendingManualDelta()
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
            charData = nil
            consumedUpdateChar = nil
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
                        var charDataFound = false
                        var consumedUpdateFound = false
                        for char in service.characteristics ?? [] {
                            if char.uuid == kCharDataUUID {
                                charData = char
                                charDataFound = true
                                p.setNotifyValue(true, for: char)
                                log("[BG-BLE] willRestoreState: setNotifyValue(true) for data char")
                            }
                            if char.uuid == kConsumedUpdateUUID {
                                consumedUpdateChar = char
                                consumedUpdateFound = true
                                log("[BG-BLE] willRestoreState: found consumedUpdate char (000A)")
                            }
                        }
                        if !charDataFound || !consumedUpdateFound {
                            var missing: [CBUUID] = []
                            if !charDataFound { missing.append(kCharDataUUID) }
                            if !consumedUpdateFound { missing.append(kConsumedUpdateUUID) }
                            log("[BG-BLE] willRestoreState: missing chars \(missing) — discovering characteristics")
                            p.discoverCharacteristics(missing, for: service)
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
        self.charData = nil
        self.consumedUpdateChar = nil
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
                peripheral.discoverCharacteristics([kCharDataUUID, kConsumedUpdateUUID], for: service)
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
            if char.uuid == kCharDataUUID {
                charData = char
                // Subscribe so we get real-time battery and daily_total_ml updates in the background.
                peripheral.setNotifyValue(true, for: char)
                NSLog("[BG-BLE] setNotifyValue(true) called for data char")
            }
            if char.uuid == kConsumedUpdateUUID {
                consumedUpdateChar = char
                NSLog("[BG-BLE] Found consumedUpdate char (000A)")
            }
        }
        // Sync any pending manual delta from widget logs after characteristics are discovered
        syncPendingManualDelta()
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

        // ── Handle DATA characteristic (battery % & daily_total_ml) ───────────
        if characteristic.uuid == kCharDataUUID,
           let data = characteristic.value,
           let payload = String(data: data, encoding: .utf8) {
            
            var batteryPct: Int?
            var dailyTotalMl: Int?
            var volumeVal: Double?
            var percentVal: Int?
            var refillVal: Double?
            var tempVal: Double?
            var bqTempVal: Double?
            var tsVal: String?

            // Parse semicolon-delimited key=value pairs: "battery=90;daily_total_ml=577;volume=450;..."
            for pair in payload.components(separatedBy: ";") {
                let kv = pair.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "=")
                if kv.count == 2 {
                    let key = kv[0].trimmingCharacters(in: .whitespaces)
                    let val = kv[1].trimmingCharacters(in: .whitespaces)
                    if key == "battery", let pct = Int(val) {
                        batteryPct = pct
                        latestBatteryPercent = pct
                    } else if key == "daily_total_ml", let total = Int(val) {
                        dailyTotalMl = total
                    } else if key == "volume", let v = Double(val) {
                        volumeVal = v
                    } else if key == "percent", let p = Int(val) {
                        percentVal = p
                    } else if (key == "refill" || key == "refills"), let r = Double(val) {
                        refillVal = r
                    } else if key == "temp", let t = Double(val) {
                        tempVal = t
                    } else if (key == "bq_temp" || key == "bqTemp"), let bqt = Double(val) {
                        bqTempVal = bqt
                    } else if key == "ts" {
                        tsVal = val
                    }
                }
            }

            if let pct = batteryPct, pct > 0 {
                if let appDefaults = UserDefaults(suiteName: kAppGroupId) {
                    appDefaults.set(pct, forKey: "battery")
                    appDefaults.synchronize()
                }
            }

            if let consumed = dailyTotalMl {
                NSLog("[BG-BLE] DATA_CHAR reported daily_total_ml=\(consumed)ml (battery=\(batteryPct ?? -1)%, volume=\(volumeVal ?? -1)ml, temp=\(tempVal ?? -1)°C)")

                // Update shared App Group UserDefaults for WidgetKit
                let todayDate = Calendar.current.startOfDay(for: Date())
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = .current
                let todayStr = formatter.string(from: Date())

                var sipDiff: Int = 0
                var currentTodayIntake: Int = 0

                if let appDefaults = UserDefaults(suiteName: kAppGroupId) {
                    let storedGoal = UserDefaults.standard.object(forKey: "flutter.water_goal") as? Int
                        ?? appDefaults.object(forKey: "daily_goal") as? Int
                        ?? 2500
                    let goal = storedGoal > 0 ? storedGoal : 2500

                    let lastUpdateDateStr = appDefaults.string(forKey: "last_update_date") ?? ""
                    let isNewDay = lastUpdateDateStr != todayStr

                    var baseline = appDefaults.integer(forKey: "bottle_baseline")
                    let lastBottleReading = appDefaults.integer(forKey: "last_bottle_reading")
                    currentTodayIntake = appDefaults.integer(forKey: "current_intake")

                    if isNewDay {
                        // Reset sub-counters for new day
                        appDefaults.set(0, forKey: "coffee_intake")
                        appDefaults.set(0, forKey: "water_intake")
                        // Clear any pending manual delta from previous day
                        appDefaults.set(0, forKey: "pending_manual_liquid_delta")

                        // Check if bottle hardware reset to 0 at midnight
                        if consumed == 0 {
                            baseline = 0
                            currentTodayIntake = 0
                            sipDiff = 0
                            NSLog("[BG-BLE] New day rollover: Bottle was reset to 0ml")
                        } else if consumed >= lastBottleReading && lastBottleReading > 0 {
                            // Bottle did NOT reset overnight: it still holds yesterday's cumulative total (e.g. 300ml or 1240ml).
                            // Establish yesterday's last known value as today's baseline offset.
                            baseline = lastBottleReading
                            let newWaterThisMorning = consumed - baseline
                            if newWaterThisMorning >= 40 && newWaterThisMorning <= 600 {
                                sipDiff = newWaterThisMorning
                                currentTodayIntake = newWaterThisMorning
                                NSLog("[BG-BLE] New day rollover: Bottle un-reset (\(consumed)ml, baseline=\(baseline)ml). Morning sip=\(sipDiff)ml")
                            } else {
                                sipDiff = 0
                                currentTodayIntake = 0
                                NSLog("[BG-BLE] New day rollover: Bottle un-reset (\(consumed)ml, baseline=\(baseline)ml). Baseline established, no fake sip.")
                            }
                        } else {
                            // consumed > 0 but lastBottleReading <= 0 or consumed < lastBottleReading
                            if consumed > 600 {
                                // Large un-reset hardware total: establish as baseline offset so it is not treated as today's consumption
                                baseline = consumed
                                sipDiff = 0
                                currentTodayIntake = 0
                                NSLog("[BG-BLE] New day rollover: Large initial bottle reading (\(consumed)ml > 600ml). Set as baseline offset to prevent fake intake.")
                            } else if consumed >= 40 {
                                baseline = 0
                                sipDiff = consumed
                                currentTodayIntake = consumed
                                NSLog("[BG-BLE] New day rollover: Bottle reset, today first sip=\(sipDiff)ml")
                            } else {
                                baseline = 0
                                sipDiff = 0
                                currentTodayIntake = consumed
                            }
                        }

                        appDefaults.set(baseline, forKey: "bottle_baseline")
                    } else {
                        // Same day:
                        if consumed == 0 {
                            // Bottle hardware temporarily reported 0 or reconnected during the day.
                            // CRITICAL: Do NOT reset currentTodayIntake to 0! Otherwise, when the next
                            // valid reading (e.g. 40ml) arrives, diff is falsely computed as 40ml again,
                            // causing duplicate history entries.
                            sipDiff = 0
                            NSLog("[BG-BLE] Bottle hardware reported 0ml during the day — preserving currentTodayIntake (\(currentTodayIntake)ml)")
                        } else {
                            if consumed < baseline {
                                baseline = 0
                                appDefaults.set(0, forKey: "bottle_baseline")
                            }

                            let calculatedTodayIntake = max(0, consumed - baseline)
                            if calculatedTodayIntake > currentTodayIntake {
                                let diff = calculatedTodayIntake - currentTodayIntake
                                if diff <= 600 {
                                    sipDiff = diff
                                    currentTodayIntake = calculatedTodayIntake
                                    NSLog("[BG-BLE] Updated App Group current_intake to \(currentTodayIntake)ml (diff: \(sipDiff)ml)")
                                } else {
                                    // Large anomalous jump (> 600ml): re-anchor baseline instead of assigning bogus total
                                    baseline = consumed - currentTodayIntake
                                    appDefaults.set(baseline, forKey: "bottle_baseline")
                                    sipDiff = 0
                                    NSLog("[BG-BLE] ⚠️ Anomalous diff of \(diff)ml ignored — re-anchored baseline to \(baseline)ml, intake remains \(currentTodayIntake)ml")
                                }
                            }
                        }
                    }

                    appDefaults.set(consumed, forKey: "last_bottle_reading")
                    appDefaults.set(currentTodayIntake, forKey: "current_intake")
                    if let pct = batteryPct, pct > 0 {
                        appDefaults.set(pct, forKey: "battery")
                    }
                    appDefaults.set(goal, forKey: "daily_goal")
                    appDefaults.set(todayStr, forKey: "last_update_date")
                    // Flag for widget to refresh immediately (not wait 5 min)
                    appDefaults.set(Date().timeIntervalSince1970, forKey: "ble_update_timestamp")
                    appDefaults.synchronize()

                    DispatchQueue.main.async {
                        if #available(iOS 14.0, *) {
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    }
                }

                // If app is in background, schedule upload to backend (debounced to avoid duplicate notifications)
                let isAppInBackground = inBackground || UIApplication.shared.applicationState != .active
                if isAppInBackground {
                    let now = Date()
                    let isDuplicate = lastUploadedConsumed == consumed &&
                        lastUploadTime != nil &&
                        now.timeIntervalSince(lastUploadTime!) < 15.0

                    if !isDuplicate {
                        lastUploadedConsumed = consumed
                        lastUploadTime = now
                        uploadTodayDataViaBackgroundSession(
                            consumed: Double(currentTodayIntake),
                            date: todayDate,
                            dayIndex: 0,
                            deviceId: peripheral.identifier.uuidString,
                            sendNotification: sipDiff >= 40,
                            battery: batteryPct
                        )

                        if sipDiff >= 40 && sipDiff <= 600 {
                            uploadTodayHistoryViaBackgroundSession(
                                sipAmount: Double(sipDiff),
                                totalAtTime: Double(currentTodayIntake),
                                battery: batteryPct,
                                volume: volumeVal,
                                percent: percentVal,
                                refill: refillVal,
                                temp: tempVal,
                                bqTemp: bqTempVal,
                                ts: tsVal,
                                bottleData: payload
                            )
                        }
                    } else {
                        NSLog("[BG-BLE] ℹ️ Skipping duplicate background upload for \(consumed)ml (uploaded \(Int(now.timeIntervalSince(lastUploadTime!)))s ago)")
                    }
                }
            }

            UIApplication.shared.endBackgroundTask(bgTaskId)
            bgTaskId = .invalid
            return
        }

        // Clean up task if unhandled characteristic
        UIApplication.shared.endBackgroundTask(bgTaskId)
        bgTaskId = .invalid
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

            updateWidget(from: "")
        } catch {
            NSLog("[BG-BLE] ❌ JSON serialization error: \(error.localizedDescription)")
            writeDebug("api_tx", "JSON_ERR")
        }
    }

    private func uploadTodayHistoryViaBackgroundSession(
        sipAmount: Double,
        totalAtTime: Double,
        battery: Int? = nil,
        volume: Double? = nil,
        percent: Int? = nil,
        refill: Double? = nil,
        temp: Double? = nil,
        bqTemp: Double? = nil,
        ts: String? = nil,
        bottleData: String? = nil
    ) {
        guard let userId = UserDefaults.standard.string(forKey: "flutter.user_id")
                ?? UserDefaults(suiteName: kAppGroupId)?.string(forKey: "flutter.user_id")
                ?? UserDefaults.standard.string(forKey: "user_id")
                ?? UserDefaults(suiteName: kAppGroupId)?.string(forKey: "user_id") else {
            NSLog("[BG-BLE] ❌ Cannot upload history: No userId found")
            return
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestampStr = isoFormatter.string(from: Date())
        let timezoneStr = TimeZone.current.identifier

        var historyItem: [String: Any] = [
            "timestamp": timestampStr,
            "consumed": sipAmount,
            "timezone": timezoneStr,
            "totalAtTime": totalAtTime
        ]
        if let batteryPct = battery {
            historyItem["percentage"] = Double(batteryPct)
            historyItem["battery"] = batteryPct
        }
        if let v = volume {
            historyItem["volume"] = v
            historyItem["remaining"] = v
        }
        if let p = percent {
            historyItem["percent"] = p
            if battery == nil {
                historyItem["percentage"] = Double(p)
            }
        }
        if let r = refill {
            historyItem["refill"] = r
            historyItem["refills"] = r
        }
        if let t = temp {
            historyItem["temp"] = t
        }
        if let bqt = bqTemp {
            historyItem["bqTemp"] = bqt
        }
        if let tsVal = ts {
            historyItem["ts"] = tsVal
        }
        if let bd = bottleData {
            historyItem["bottleData"] = bd
        }

        let body: [String: Any] = [
            "userId": userId,
            "history": [historyItem]
        ]

        guard let uploadURL = URL(string: "https://api.sipnudge.com/api/database/sync-today-history") else {
            NSLog("[BG-BLE] ❌ Invalid URL for sync-today-history")
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

            NSLog("[BG-BLE] 📤 Scheduling background sync-today-history for user \(userId) (sip: \(sipAmount)ml, totalAtTime: \(totalAtTime)ml, vol: \(volume ?? -1)ml, temp: \(temp ?? -1)°C)")

            BackgroundSessionManager.shared.scheduleUpload(
                url: uploadURL,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: jsonData
            )
        } catch {
            NSLog("[BG-BLE] ❌ JSON serialization error in sync-today-history: \(error.localizedDescription)")
        }
    }

    /// Internal (not private) so AppDelegate can trigger it via MethodChannel.
    func connectToSavedDevice() {
        if let p = peripheral, p.state == .connected, charData != nil {
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

    private func updateWidget(from payload: String = "") {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if #available(iOS 14.0, *) {
                NSLog("[BG-BLE] 🔄 Triggering WidgetCenter.shared.reloadAllTimelines() 3 seconds after API trigger")
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        // Second reload after 10 seconds to catch server response
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if #available(iOS 14.0, *) {
                NSLog("[BG-BLE] 🔄 Second WidgetCenter.shared.reloadAllTimelines() 10 seconds after API trigger")
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
