import UIKit
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        // Battery channel
        let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                                 binaryMessenger: controller.binaryMessenger)
        batteryChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getBatteryLevel" {
                self.receiveBatteryLevel(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        // Device info channel
        let deviceInfoChannel = FlutterMethodChannel(name: "samples.flutter.dev/device_info",
                                                    binaryMessenger: controller.binaryMessenger)
        deviceInfoChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getDeviceManufacturer" {
                self.receiveDeviceManufacturer(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        // Browser channel
        let browserChannel = FlutterMethodChannel(name: "samples.flutter.dev/browser",
                                                binaryMessenger: controller.binaryMessenger)
        browserChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "openUrl" {
                guard let args = call.arguments as? [String: String],
                      let urlString = args["url"] else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL not provided", details: nil))
                    return
                }
                self.openUrl(urlString: urlString)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: "UNAVAILABLE", message: "Battery level not available.", details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }

    private func receiveDeviceManufacturer(result: FlutterResult) {
        // On iOS, Apple is always the manufacturer
        result("Apple")
    }

    private func openUrl(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
