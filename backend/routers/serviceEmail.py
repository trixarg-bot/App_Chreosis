from fastapi import APIRouter, Request, HTTPException, Depends
from fastapi.responses import RedirectResponse
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import os
import base64
import json
from dotenv import load_dotenv
import time
import requests
from sqlalchemy.orm import Session
from database import get_db
from models import Usuario, GmailToken
from utils.security import verify_password
from utils.email_processor import process_and_save_email
from datetime import datetime, timedelta
from pydantic import BaseModel

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

router = APIRouter(
    prefix="/gmail",
    tags=["gmail"]
)

# Cargar las variables de entorno
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
REDIRECT_URI = os.getenv("REDIRECT_URI")
SCOPES = os.getenv("SCOPES")

GOOGLE_CLIENT_CONFIG = {
    "web": {
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "redirect_uris": [REDIRECT_URI],
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token"
    }
}

# class StopGmailRequest(BaseModel):
#     email: str
#     password: str

@router.get("/login")
async def login():
    """Inicia el flujo de autorización de Gmail"""
    flow = Flow.from_client_config(
        GOOGLE_CLIENT_CONFIG,
        scopes=SCOPES
    )
    flow.redirect_uri = REDIRECT_URI
    
    auth_url, state = flow.authorization_url(
        prompt='consent',
        access_type='offline',
        include_granted_scopes='true'
    )
    
    # En lugar de redirigir, devolvemos la URL
    return {"authorization_url": auth_url}
#TODO: REGISTRAR EMAIL CORRECTAMENTE
@router.get("/oauth/callback")
async def oauth_callback(
    request: Request, 
    db: Session = Depends(get_db)
):
    try:
        flow = Flow.from_client_config(
            GOOGLE_CLIENT_CONFIG,
            scopes=SCOPES
        )
        flow.redirect_uri = REDIRECT_URI

        authorization_response = str(request.url)
        flow.fetch_token(authorization_response=authorization_response)

        credentials = flow.credentials
        
        # Obtener el email del usuario
        service = build('gmail', 'v1', credentials=credentials)
        profile = service.users().getProfile(userId='me').execute()
        email = profile['emailAddress']

        # Guardar las credenciales y email para uso futuro
        gmail_credentials = {
            "token": credentials.token,
            "refresh_token": credentials.refresh_token,
            "token_uri": credentials.token_uri,
            "client_id": credentials.client_id,
            "client_secret": credentials.client_secret,
            "scopes": SCOPES,
            "email": email
        }
        
        # Configurar watch en Gmail
        watch_request = {
            'labelIds': ['INBOX'],
            'topicName': 'projects/vast-ascent-443822-d0/topics/Chreosis',
            'labelFilterBehavior': 'INCLUDE'
        }
        service.users().watch(userId='me', body=watch_request).execute()

        # Aquí podrías mostrar una página de éxito o redirigir a la app
        return {
            "message": "Gmail conectado exitosamente", 
            "email": email
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error en callback de Gmail: {str(e)}"
        )

@router.post("/notifications")
async def gmail_notifications(
    request: Request,
    db: Session = Depends(get_db)
):
    try:
        data = await request.json()
        print("📥 Notificación recibida:", json.dumps(data, indent=2))

        encoded_data = data["message"]["data"]
        decoded_bytes = base64.urlsafe_b64decode(encoded_data)
        decoded_json = json.loads(decoded_bytes.decode("utf-8"))
        history_id = decoded_json.get("historyId")

        if not history_id:
            raise ValueError("No se encontró historyId en el mensaje decodificado.")

        # Primero obtenemos todos los tokens activos
        gmail_tokens = db.query(GmailToken).all()
        if not gmail_tokens:
            print("⚠️ No hay tokens disponibles para procesar notificaciones.")
            return {"status": "IGNORED", "reason": "No Gmail tokens available"}
            

        # Iteramos sobre cada token hasta encontrar el correcto
        for gmail_token in gmail_tokens:
            try:
                creds = Credentials(
                    token=gmail_token.access_token,
                    refresh_token=gmail_token.refresh_token,
                    token_uri=gmail_token.token_uri,
                    client_id=gmail_token.client_id,
                    client_secret=gmail_token.client_secret,
                    scopes=json.loads(gmail_token.scopes)
                )

                service = build('gmail', 'v1', credentials=creds)
                
                # Obtener el perfil del usuario para verificar el email
                profile = service.users().getProfile(userId='me').execute()
                user_email = profile['emailAddress']
                
                # Buscar el usuario con ese email
                usuario = db.query(Usuario).filter(Usuario.email == user_email).first()
                if not usuario or usuario.id != gmail_token.usuario_id:
                    continue

                # Si llegamos aquí, encontramos el token correcto
                result = service.users().messages().list(userId='me', labelIds=['INBOX'], maxResults=1).execute()
                
                for msg in result.get('messages', []):
                    msg_id = msg['id']
                    full_message = service.users().messages().get(userId='me', id=msg_id, format='full').execute()
                    is_unread = 'UNREAD' in full_message.get('labelIds', [])
                    headers = full_message['payload'].get('headers', [])
                    subject = next((h['value'] for h in headers if h['name'] == 'Subject'), '(Sin asunto)')

                    if not is_unread or 'Notificación de Consumo' not in subject:
                        continue

                    # Extraer el contenido del correo
                    body = ''
                    parts = full_message['payload'].get('parts', [])
                    for part in parts:
                        if part.get("mimeType") == "text/plain":
                            body_data = part['body'].get('data')
                            if body_data:
                                body = base64.urlsafe_b64decode(body_data).decode("utf-8")
                                break

                    if body:
                        # Procesar el correo con GPT y guardar en la base de datos
                        result = await process_and_save_email(
                            db=db,
                            email_content=body,
                            usuario_id=usuario.id
                        )
                        
                        # Notificar el resultado
                        notification_message = (
                            "✅ Transacción procesada y guardada correctamente" 
                            if result["Status"] == "APROBADA" 
                            else "❌ No se pudo procesar la transacción"
                        )
                        
                        requests.post(
                            "https://ntfy.sh/Chreosis", 
                            data=notification_message,
                            headers={
                                "Title": f"Procesamiento de correo para {user_email}",
                                "Tags": "white_check_mark" if result["Status"] == "APROBADA" else "x",
                            }
                        )

                return {"status": "OK", "email": user_email}

            except Exception as e:
                print(f"Error al procesar token: {str(e)}")
                continue

        print("⚠️ No se encontró un token válido para esta notificación.")
        return {"status": "IGNORED", "reason": "No valid token matched"}

    except Exception as e:
        print("❌ Error procesando la notificación:", str(e))
        raise HTTPException(status_code=400, detail=f"Error al procesar notificación: {str(e)}")

@router.post("/stop")
async def stop_notifications(
    # stop_request: StopGmailRequest,
    db: Session = Depends(get_db)
):
    try:
        usuario = db.query(Usuario).filter(Usuario.email == stop_request.email).first()
        if not usuario:
            raise HTTPException(status_code=401, detail="Credenciales incorrectas")

        try:
            is_valid = verify_password(stop_request.password, usuario.password)
            if not is_valid:
                raise HTTPException(status_code=401, detail="Credenciales incorrectas")
        except Exception as e:
            print(f"Error al verificar contraseña: {str(e)}")
            raise HTTPException(status_code=401, detail="Error al verificar credenciales")

        gmail_token = db.query(GmailToken).filter(GmailToken.usuario_id == usuario.id).first()
        if not gmail_token:
            raise HTTPException(status_code=404, detail="No se encontró configuración de Gmail para este usuario")

        try:
            creds = Credentials(
                token=gmail_token.access_token,
                refresh_token=gmail_token.refresh_token,
                token_uri=gmail_token.token_uri,
                client_id=gmail_token.client_id,
                client_secret=gmail_token.client_secret,
                scopes=json.loads(gmail_token.scopes)
            )

            service = build('gmail', 'v1', credentials=creds)
            service.users().stop(userId='me').execute()

            db.delete(gmail_token)
            db.commit()

            return {
                "status": "stopped", 
                "message": f"Las notificaciones de Gmail fueron detenidas para {stop_request.email}"
            }

        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail=f"Error al detener el servicio de Gmail: {str(e)}")

    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Error inesperado: {str(e)}")
        raise HTTPException(status_code=500, detail="Error inesperado al procesar la solicitud")