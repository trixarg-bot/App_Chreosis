import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chreosis_app/db/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  // URL base del servidor - deberías moverlo a variables de entorno
  static const String _baseUrl = 'https://4886e5449d2d.ngrok.app';

  static Future<void> initialize() async {
    // Inicializar Firebase
    await Firebase.initializeApp();

    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Configurar notificaciones locales
      await _initializeLocalNotifications();

      // Configurar handlers para mensajes
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  static Future<String?> _getDeviceToken() async {
    try {
        print("Intentando obtener token FCM...");
        // Asegurarnos que Firebase está inicializado
        await Firebase.initializeApp();
        print("Firebase inicializado");
        
        final token = await _messaging.getToken();
        print("Token obtenido: $token");
        return token;
    } catch (e) {
        print('Error obteniendo token FCM: $e');
        return null;
    }
  }

  static Future<bool> _registerDeviceOnServer(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/devices/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': token,
          'nombre_dispositivo': 'Dispositivo móvil',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error registrando dispositivo: ${response.body}');
      }

      print('Dispositivo registrado exitosamente');
      return true;
    } catch (e) {
      print('Error registrando dispositivo: $e');
      return false;
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje recibido en foreground: ${message.data}');
    
    if (message.data['type'] == 'new_transaction') {
      final transactionData = message.data['transaction'];
      await _saveTransaction(transactionData);
      
      await _showLocalNotification(
        title: message.notification?.title ?? 'Nueva Transacción',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _saveTransaction(Map<String, dynamic> transactionData) async {
    try {
      // Aquí deberías guardar la transacción en SQLite usando DatabaseHelper
      // La transacción ya viene procesada desde el servidor
      print('Guardando transacción: $transactionData');
      // TODO: Implementar guardado en SQLite
    } catch (e) {
      print('Error guardando transacción: $e');
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (message.data['type'] == 'new_transaction') {
      await _saveTransaction(message.data['transaction']);
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> _handleLocalNotificationTap(
    NotificationResponse response,
  ) async {
    // Implementar navegación a la pantalla de transacciones
  }

  // Método para iniciar el proceso de registro de Gmail y dispositivo
  static Future<void> connectGmailAndRegisterDevice() async {
    try {
      // Primero obtener el token FCM
      final token = await _getDeviceToken();
      if (token == null) {
        throw 'No se pudo obtener el token del dispositivo';
      }

      // Registrar el dispositivo en el servidor
      final deviceRegistered = await _registerDeviceOnServer(token);
      if (!deviceRegistered) {
        throw 'Error registrando el dispositivo';
      }

      // Iniciar el proceso de autenticación de Gmail
      final response = await http.get(
            Uri.parse('$_baseUrl/gmail/login'),
        );

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final authUrl = data['authorization_url'];
            
            // Crear la URI y codificarla correctamente
            final uri = Uri.parse(authUrl);
            
            // Usar launchUrl con las opciones correctas
            final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
                webViewConfiguration: const WebViewConfiguration(
                    enableJavaScript: true,
                    enableDomStorage: true,
                ),
            );
            
            if (!launched) {
                throw 'No se pudo abrir el navegador. Por favor, intenta abrir manualmente: $authUrl';
            }
        } else {
            throw 'Error del servidor: ${response.statusCode}';
        }
    } catch (e) {
        print('Error detallado: $e');
        rethrow;
    }
  }
} 