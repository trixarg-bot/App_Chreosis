import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Configurar notificaciones
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      // Solicitar permisos con más opciones
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Permisos de notificación concedidos")
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          } else {
            print("❌ Permisos de notificación denegados")
            if let error = error {
              print("Error detallado: \(error.localizedDescription)")
            }
          }
        }
      )
    }
    
    // Registrar para notificaciones remotas inmediatamente
    application.registerForRemoteNotifications()
    
    // Configurar Firebase Messaging
    Messaging.messaging().delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Manejar notificaciones en primer plano
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📱 Notificación recibida en primer plano")
    // Mostrar la notificación incluso cuando la app está en primer plano
    completionHandler([.sound, .badge, .alert])
  }
  
  // Manejar interacción con la notificación
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("📱 Usuario interactuó con la notificación")
    let userInfo = response.notification.request.content.userInfo
    print("📦 Datos de la notificación: \(userInfo)")
    completionHandler()
  }
  
  // Manejar el registro exitoso para notificaciones remotas
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("✅ Token APNS registrado exitosamente: \(token)")
  }
  
  // Manejar errores en el registro de notificaciones remotas
  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Error registrando para notificaciones remotas: \(error.localizedDescription)")
  }
  
  // Manejar mensajes en segundo plano
  override func application(_ application: UIApplication,
                          didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                          fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📱 Notificación recibida en segundo plano: \(userInfo)")
    
    // Verificar el estado de la aplicación
    let state = application.applicationState
    print("📱 Estado de la aplicación: \(state.rawValue)")
    
    // Verificar configuración de notificaciones
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("📱 Configuración de notificaciones:")
      print("Autorización: \(settings.authorizationStatus.rawValue)")
      print("Alertas: \(settings.alertSetting.rawValue)")
      print("Badges: \(settings.badgeSetting.rawValue)")
      print("Sonidos: \(settings.soundSetting.rawValue)")
    }
    
    completionHandler(UIBackgroundFetchResult.newData)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔄 Token FCM actualizado: \(fcmToken ?? "nil")")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
