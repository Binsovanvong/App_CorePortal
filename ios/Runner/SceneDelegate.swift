import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var blurOverlay: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    if let windowScene = scene as? UIWindowScene, let window = windowScene.windows.first, blurOverlay == nil {
      let blur = UIBlurEffect(style: .systemUltraThinMaterial)
      let blurView = UIVisualEffectView(effect: blur)
      blurView.frame = window.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blurView.tag = 8889
      window.addSubview(blurView)
      self.blurOverlay = blurView
    }
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    if let windowScene = scene as? UIWindowScene, let window = windowScene.windows.first {
      window.viewWithTag(8889)?.removeFromSuperview()
      blurOverlay = nil
    }
  }
}
