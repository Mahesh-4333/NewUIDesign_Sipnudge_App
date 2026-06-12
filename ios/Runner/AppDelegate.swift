import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var backgroundTask: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     if #available(iOS 10.0, *) {
         UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
         }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    
    backgroundTask = application.beginBackgroundTask(withName: "SipnudgeKeepAlive") {
      application.endBackgroundTask(self.backgroundTask)
      self.backgroundTask = .invalid
    }
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    super.applicationWillEnterForeground(application)
    
    if backgroundTask != .invalid {
      application.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    let content = UNMutableNotificationContent()
    content.title = "Sipnudge is closed"
    content.body = "Auto sync won't happen from bottle if app is not in background."
    content.sound = UNNotificationSound.default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "app_terminated_warning", content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling termination notification: \(error)")
        }
    }
    
    if backgroundTask != .invalid {
      application.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
    
    Thread.sleep(forTimeInterval: 0.1)
  }
}
