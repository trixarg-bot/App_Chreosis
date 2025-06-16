import firebase_admin
from firebase_admin import credentials, messaging
from typing import Dict, List

class FirebaseAdmin:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(FirebaseAdmin, cls).__new__(cls)
            cls._instance._initialize()
        return cls._instance

    def _initialize(self):
        try:
            print("🚀 Inicializando Firebase Admin SDK...")
            cred = credentials.Certificate('/Users/eduardoliriano/codigos/Chreosis/chreosis_app/backend/utils/chreosis-a4492-firebase-adminsdk-fbsvc-2d30c216cd.json')
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK inicializado correctamente")
        except Exception as e:
            print(f"❌ Error inicializando Firebase Admin SDK: {e}")
            raise

    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Dict = None
    ) -> bool:
        try:
            print(f"📤 Enviando notificación a token: {fcm_token}")
            print(f"📝 Título: {title}")
            print(f"📝 Cuerpo: {body}")
            print(f"📦 Datos: {data}")

            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                token=fcm_token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='default_channel',
                        priority='high',
                        default_sound=True,
                        default_vibrate_timings=True,
                        default_light_settings=True
                    )
                )
            )
            
            response = messaging.send(message)
            print(f"✅ Notificación enviada exitosamente. Response: {response}")
            return True
        except Exception as e:
            print(f"❌ Error enviando notificación: {e}")
            return False

    async def send_multicast(
        self,
        fcm_tokens: List[str],
        title: str,
        body: str,
        data: Dict = None
    ) -> Dict:
        try:
            print(f"📤 Enviando notificación multicast a {len(fcm_tokens)} tokens")
            print(f"📝 Título: {title}")
            print(f"📝 Cuerpo: {body}")
            print(f"📦 Datos: {data}")

            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                tokens=fcm_tokens,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='default_channel',
                        priority='high',
                        default_sound=True,
                        default_vibrate_timings=True,
                        default_light_settings=True
                    )
                )
            )
            
            response = messaging.send_multicast(message)
            print(f"✅ Notificación multicast enviada. Respuesta: {response}")
            return {
                "success_count": response.success_count,
                "failure_count": response.failure_count
            }
        except Exception as e:
            print(f"❌ Error en multicast: {e}")
            return {"success_count": 0, "failure_count": len(fcm_tokens)} 