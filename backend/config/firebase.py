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
        cred = credentials.Certificate('/Users/eduardoliriano/codigos/Chreosis/chreosis_app/backend/utils/chreosis-a4492-firebase-adminsdk-fbsvc-2d30c216cd.json')
        firebase_admin.initialize_app(cred)

    async def send_notification(
        self,
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
        except Exception as e:
            print(f"Error enviando notificación: {e}")
            return False

    async def send_multicast(
        self,
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