import UIKit
import Flutter
// import opencv2

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Flutterから呼び出されるための準備
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let opencvChannel = FlutterMethodChannel(name: "com.miyatalab.pear74/opencv", binaryMessenger: controller.binaryMessenger)
        
        // com.miyatalab.pear74/opencvのチャンネルで呼び出されたときの処理
        opencvChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if call.method == "JudgeColorChart" {
                // JudgeColorChartを呼ばれた場合は、
                // 引数を受け取って関数を呼ぶ
                let parameters = call.arguments as! Dictionary<String, Any>
                let picPath = parameters["picPath"] as! String
                let procPath = parameters["procPath"] as! String
                self?.JudgeColorChart(picPath: picPath, procPath: procPath, result: result)
            } else {
                // 未実装の関数を指定された場合は(大抵の場合間違い)、
                // 実装されていないことを知らせる
                result(FlutterMethodNotImplemented)
                return
            }
        })
    
        // Flutterによって予め用意されていた部分
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func JudgeColorChart(picPath: String, procPath: String, result: FlutterResult) {
        result(procPath)
    }
}
