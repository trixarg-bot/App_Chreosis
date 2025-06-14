# Implementación de Notificaciones Push y Almacenamiento Local

## Índice
1. [Configuración del Servidor](#1-configuración-del-servidor)
2. [Configuración de la App Flutter](#2-configuración-de-la-app-flutter)
3. [Manejo de Datos Offline](#3-manejo-de-datos-offline)
4. [Consideraciones de Seguridad](#4-consideraciones-de-seguridad)
5. [Troubleshooting](#5-troubleshooting)

## 1. Configuración del Servidor

### 1.1 Configurar Firebase Admin SDK

1. Instalar dependencias:
```bash
pip install firebase-admin
```

2. Configurar Firebase Admin en el servidor (`backend/config/firebase.py`):
```python
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)
```

3. Crear servicio de notificaciones (`backend/services/notification_service.py`):
```python
from firebase_admin import messaging
from typing import Dict, List

class NotificationService:
    @staticmethod
    async def send_notification(
        fcm_token: str,
        title: str,
        body: str,
        data: Dict = None
    ) -> bool:
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data,
                token=fcm_token
            )
            
            response = messaging.send(message)
            return True
        except messaging.ApiCallError as e:
            print(f"Error enviando notificación: {e}")
            return False
        except Exception as e:
            print(f"Error inesperado: {e}")
            return False

    @staticmethod
    async def send_multicast(
        fcm_tokens: List[str],
        title: str,
        body: str,
        data: Dict = None
    ) -> Dict:
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data,
                tokens=fcm_tokens
            )
            
            response = messaging.send_multicast(message)
            return {
                "success_count": response.success_count,
                "failure_count": response.failure_count
            }
        except Exception as e:
            print(f"Error en multicast: {e}")
            return {"success_count": 0, "failure_count": len(fcm_tokens)}
```

### 1.2 Modificar el Modelo de Usuario

1. Actualizar el modelo (`backend/models.py`):
```python
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    dispositivos = relationship("Dispositivo", back_populates="usuario")

class Dispositivo(Base):
    __tablename__ = "dispositivos"
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    fcm_token = Column(String, nullable=False)
    nombre_dispositivo = Column(String)
    ultimo_acceso = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    usuario = relationship("Usuario", back_populates="dispositivos")
```


### 1.3 Implementar Endpoints para FCM

1. Crear router para dispositivos (`backend/routers/devices.py`):
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from database import get_db
from models import Usuario, Dispositivo
from schemas import DispositivoCreate, DispositivoResponse
from dependencies import get_current_user

router = APIRouter(prefix="/devices", tags=["devices"])

@router.post("/register", response_model=DispositivoResponse)
async def register_device(
    device: DispositivoCreate,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Verificar si el token ya existe
        existing_device = db.query(Dispositivo).filter(
            Dispositivo.fcm_token == device.fcm_token
        ).first()

        if existing_device:
            # Actualizar dispositivo existente
            existing_device.ultimo_acceso = datetime.utcnow()
            existing_device.nombre_dispositivo = device.nombre_dispositivo
            db.commit()
            return existing_device

        # Crear nuevo dispositivo
        new_device = Dispositivo(
            usuario_id=current_user.id,
            fcm_token=device.fcm_token,
            nombre_dispositivo=device.nombre_dispositivo,
            ultimo_acceso=datetime.utcnow()
        )
        db.add(new_device)
        db.commit()
        db.refresh(new_device)
        return new_device

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error registrando dispositivo: {str(e)}"
        )

@router.delete("/unregister/{device_id}")
async def unregister_device(
    device_id: int,
    current_user: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    device = db.query(Dispositivo).filter(
        Dispositivo.id == device_id,
        Dispositivo.usuario_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(status_code=404, detail="Dispositivo no encontrado")

    db.delete(device)
    db.commit()
    return {"message": "Dispositivo eliminado correctamente"}
```

## 2. Configuración de la App Flutter

### 2.1 Configurar Firebase Cloud Messaging

1. Agregar dependencias en `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
```

2. Inicializar Firebase (`lib/services/firebase_service.dart`):
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

      // Obtener token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        await _registerDeviceOnServer(token);
      }

      // Escuchar cambios del token
      _messaging.onTokenRefresh.listen(_registerDeviceOnServer);

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

  static Future<void> _registerDeviceOnServer(String token) async {
    try {
      // Implementar llamada a tu API
      final response = await ApiService.registerDevice(token);
      print('Dispositivo registrado: $response');
    } catch (e) {
      print('Error registrando dispositivo: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Mensaje recibido en foreground: ${message.data}');
    
    if (message.data['type'] == 'new_transaction') {
      // Guardar transacción en SQLite
      await DatabaseService.saveTransaction(message.data['transaction']);
      
      // Mostrar notificación local
      await _showLocalNotification(
        title: message.notification?.title ?? 'Nueva Transacción',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Mensaje abierto desde background: ${message.data}');
    // Implementar navegación o acción específica
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    // Implementar navegación o acción al tocar la notificación
  }
}
```
## 3. Manejo de Datos Offline

### 3.1 Implementar Sincronización

1. Crear servicio de sincronización (`lib/services/sync_service.dart`):
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static Future<void> initialize() async {
    // Escuchar cambios de conectividad
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncData();
      }
    });

    // Iniciar sincronización periódica
    _startPeriodicSync();
  }

  static void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 15), (_) => syncData());
  }

  static Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final unsyncedTransactions = await DatabaseService.getUnsyncedTransactions();
      
      for (var transaction in unsyncedTransactions) {
        try {
          // Intentar sincronizar con el servidor
          await ApiService.syncTransaction(transaction);
          await DatabaseService.markAsSynced(transaction['id']);
        } catch (e) {
          print('Error sincronizando transacción: $e');
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static void dispose() {
    _syncTimer?.cancel();
  }
}
```

### 3.2 Manejo de Errores

1. Implementar sistema de reintentos (`lib/utils/retry_helper.dart`):
```dart
class RetryHelper {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
  }
}
```

## 4. Consideraciones de Seguridad

1. Nunca almacenar tokens sensibles en texto plano
2. Implementar expiración de tokens FCM
3. Validar origen de las notificaciones
4. Encriptar datos sensibles en SQLite

## 5. Troubleshooting

### Problemas Comunes y Soluciones

1. **No se reciben notificaciones**
   - Verificar permisos de notificaciones
   - Comprobar token FCM válido
   - Revisar configuración de Firebase

2. **Errores de sincronización**
   - Implementar sistema de logs
   - Verificar conectividad
   - Validar formato de datos

3. **Problemas de almacenamiento**
   - Implementar limpieza periódica
   - Manejar errores de SQLite
   - Verificar espacio disponible

### Monitoreo y Logging

1. Implementar sistema de logging:
```dart
class Logger {
  static Future<void> log(
    String message,
    {LogLevel level = LogLevel.info}
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '$timestamp [$level] $message';
    
    // Guardar log localmente
    await _saveLog(logEntry);
    
    // Si es error, enviar al servidor
    if (level == LogLevel.error) {
      await _sendLogToServer(logEntry);
    }
  }
}
``` 

2. para redirigir a la pagina de auntenticacion de google en ios:

Agregar estos a ios/Runner/Info.plist

```xml
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>https</string>
    <string>http</string>
  </array>
```