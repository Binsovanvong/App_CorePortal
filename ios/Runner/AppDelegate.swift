import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Cover confidential app content when switching tasks or minimizing
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    guard let window = self.window, privacyOverlay == nil else { return }
    let blur = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurView = UIVisualEffectView(effect: blur)
    blurView.frame = window.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.tag = 8888
    window.addSubview(blurView)
    self.privacyOverlay = blurView
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    window?.viewWithTag(8888)?.removeFromSuperview()
    privacyOverlay = nil
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
