import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:chreosis_app/models/transaccion.dart';
import 'package:provider/provider.dart';
import 'package:chreosis_app/providers/categoria_provider.dart';
import 'package:chreosis_app/providers/cuenta_provider.dart';
import 'package:chreosis_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:chreosis_app/models/categoria.dart';

class FirebaseService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  //TODO: URL base del servidor - deberías moverlo a variables de entorno
  static const String _baseUrl = 'https://api-chreosis-production.up.railway.app';

  static Future<void> initialize() async {
    try {
      print("🚀 Iniciando Firebase...");
      // Inicializar Firebase
      await Firebase.initializeApp();
      print("✅ Firebase inicializado correctamente");

      // Solicitar permisos de notificación para Android 13+
      if (await Permission.notification.request().isGranted) {
        print("✅ Permisos de notificación concedidos para Android 13+");
      } else {
        print("⚠️ Permisos de notificación no concedidos para Android 13+");
      }

      // Solicitar permisos de FCM
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print("📱 Estado de permisos de notificaciones: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("✅ Permisos de notificaciones concedidos");
        
        // Configurar notificaciones locales
        await _initializeLocalNotifications();
        print("✅ Notificaciones locales inicializadas");

        // Obtener token FCM
        String? token = await _messaging.getToken();
        print("📱 Token FCM obtenido: $token");
        
        if (token != null) {
          await _registerDeviceOnServer(token);
        }

        // Escuchar cambios del token
        _messaging.onTokenRefresh.listen((newToken) {
          print("🔄 Token FCM actualizado: $newToken");
          _registerDeviceOnServer(newToken);
        });

        // Configurar handlers para mensajes
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print("📨 Mensaje recibido en foreground: ${message.data}");
          _handleForegroundMessage(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print("📨 Mensaje abierto desde background: ${message.data}");
          _handleBackgroundMessage(message);
        });

        // Manejar mensajes cuando la app está cerrada
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          print("📨 Mensaje inicial recibido: ${initialMessage.data}");
          _handleBackgroundMessage(initialMessage);
        }
      } else {
        print("⚠️ Permisos de notificaciones no concedidos");
      }
    } catch (e) {
      print("❌ Error inicializando Firebase: $e");
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    // Crear el canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'default_channel',
      'Default Channel',
      description: 'Canal de notificaciones por defecto',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Crear el canal en el sistema
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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
    print('📨 Procesando mensaje en foreground: ${message.data}');
    
    if (message.data['type'] == 'new_transaction') {
      final transactionData = message.data;
      print('💾 Guardando transacción: $transactionData');
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
      print('💾 Guardando transacción: $transactionData');
      
      // Obtener el usuario actual (por ahora usaremos el ID 1 como default)
      // TODO: Implementar lógica para obtener el usuario actual
      const userId = 1;
      
      // Obtener la categoría por nombre usando el CategoriaProvider
      final categoriaProvider = Provider.of<CategoriaProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await categoriaProvider.cargarCategorias(userId);

      // Buscar la categoría por nombre
      Categoria categoria;
      try {
        categoria = categoriaProvider.categorias.firstWhere(
          (cat) =>
              cat.name.toLowerCase() ==
              transactionData['categoria'].toLowerCase(),
        );
      } catch (e) {
        // Si no se encuentra la categoría, buscar o crear "Sin categorizar"
        try {
          categoria = categoriaProvider.categorias.firstWhere(
            (cat) => cat.name.toLowerCase() == 'sin categorizar',
          );
        } catch (e) {
          // Si no existe "Sin categorizar", crearla usando el provider
          await categoriaProvider.insertCategoria(
            userId: userId,
            name: 'Sin categorizar',
            type: 'indefinido',
            iconCode: Icons.help_outline.codePoint,
          );
          // Recargar las categorías para obtener la nueva
          await categoriaProvider.cargarCategorias(userId);
          categoria = categoriaProvider.categorias.firstWhere(
            (cat) => cat.name.toLowerCase() == 'sin categorizar',
          );
        }
      }

      // Obtener la cuenta 6por defecto usando el CuentaProvider
      final cuentaProvider = Provider.of<CuentaProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await cuentaProvider.cargarCuentas(userId);

      if (cuentaProvider.cuentas.isEmpty) {
        throw Exception('No se encontró ninguna cuenta para el usuario');
      }

      final cuenta = cuentaProvider.cuentas.first;

      // Crear la transacción
      final transaccion = Transaccion(
        userId: userId,
        categoryId: categoria.id!,
        accountId: cuenta.id!,
        date: transactionData['fecha'],
        amount: double.parse(transactionData['monto']),
        type: 'gasto', // Por defecto es un gasto
        note: transactionData['lugar'],
        createdAt: DateTime.now().toIso8601String(),
        moneda: transactionData['moneda'],
        conversion: transactionData['isconversion']
      );

      // Guardar la transacción usando el TransactionProvider
      final transactionProvider = Provider.of<TransactionProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      await transactionProvider.agregarTransaccion(transaccion);
      await Provider.of<CuentaProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).cargarCuentas(userId);
      print('✅ Transacción guardada exitosamente');
      
    } catch (e) {
      print('❌ Error guardando transacción: $e');
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (message.data['type'] == 'new_transaction') {
      await _saveTransaction(message.data);
      
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('🔔 Mostrando notificación local: $title - $body');
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payload,
      );
      print('✅ Notificación local mostrada correctamente');
    } catch (e) {
      print('❌ Error mostrando notificación local: $e');
    }
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
      final response = await http.get(Uri.parse('$_baseUrl/gmail/login'));

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final authUrl = data['authorization_url'];
            
            // Crear la URI y codificarla correctamente
            final uri = Uri.parse(authUrl);
            if (uri.scheme != 'https') {
              throw 'La URL de autenticación debe usar HTTPS';
            }
            
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