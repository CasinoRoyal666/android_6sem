import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(name: "com.example.student_dashboard/device",
                                                 binaryMessenger: controller.binaryMessenger)

        batteryChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getBatteryLevel" {
                let batteryLevel = self.getBatteryLevel()
                if batteryLevel != -1 {
                    result(batteryLevel)
                } else {
                    result(FlutterError(code: "UNAVAILABLE",
                                        message: "Battery level not available.",
                                        details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func getBatteryLevel() -> Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        return batteryLevel >= 0 ? Int(batteryLevel * 100) : -1
    }
}
