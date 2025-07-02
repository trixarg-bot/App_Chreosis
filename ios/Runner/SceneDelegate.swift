// import UIKit
// import Flutter

// @available(iOS 13.0, *)
// class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//     var window: UIWindow?

//     func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//         guard let windowScene = (scene as? UIWindowScene) else { return }
        
//         window = UIWindow(windowScene: windowScene)
        
//         let controller = FlutterViewController()
//         window?.rootViewController = controller
//         window?.makeKeyAndVisible()
        
//         // Manejar notificaciones cuando la app se abre desde una notificación
//         if let notification = connectionOptions.notificationResponse {
//             print("📱 App abierta desde notificación: \(notification.notification.request.content.userInfo)")
//         }
//     }

//     func sceneDidDisconnect(_ scene: UIScene) {
//         // Called when the scene is being released by the system.
//     }

//     func sceneDidBecomeActive(_ scene: UIScene) {
//         // Called when the scene has moved from an inactive state to an active state.
//     }

//     func sceneWillResignActive(_ scene: UIScene) {
//         // Called when the scene will move from an active state to an inactive state.
//     }

//     func sceneWillEnterForeground(_ scene: UIScene) {
//         // Called as the scene transitions from the background to the foreground.
//     }

//     func sceneDidEnterBackground(_ scene: UIScene) {
//         // Called as the scene transitions from the foreground to the background.
//     }
// } 