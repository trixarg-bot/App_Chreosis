from typing import Dict, Optional
from openai import AsyncOpenAI
from sqlalchemy.orm import Session
from models import Transaccion, Usuario, Dispositivo
from datetime import datetime
import json
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde la raíz del proyecto
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

# Configurar cliente de OpenAI
client = AsyncOpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

async def process_email_with_gpt(email_content: str) -> Dict:
    """
    Procesa el contenido del email usando GPT para extraer información relevante.
    Retorna un JSON con la información estructurada.
    """
    try:
        # Prompt para GPT que explica cómo estructurar la información
        prompt = f"""
        Analiza el siguiente correo electrónico y extrae la siguiente información en formato JSON:
        - Monto: el valor numérico del gasto/ingreso
        - Fecha: la fecha de la transacción
        - Categoria: Casa
        - Moneda: tipo de moneda en este unico formato: (DOP, USD, EUR, etc.)
        - Lugar: lugar o establecimiento donde se realizó la transacción
        - Status: 'APROBADA' si es una transacción válida, 'RECHAZADA' si no se pudo procesar correctamente

        El correo a analizar es:
        {email_content}

        Responde SOLO con el JSON, sin ningún texto adicional. Ejemplo del formato esperado:
        {{
            "Monto": 100.50,
            "Fecha": "2024-03-20",
            "Categoria": "Alimentos",
            "Moneda": "USD",
            "Lugar": "Supermercado XYZ",
            "Status": "APROBADA"
        }}
        """

        # Llamada a la API de OpenAI usando el nuevo cliente
        response = await client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "Eres un asistente especializado en extraer información financiera de correos electrónicos."},
                {"role": "user", "content": prompt}
            ]
        )

        # Extraer y parsear la respuesta JSON
        json_response = json.loads(response.choices[0].message.content)
        print(json_response)
        return json_response

    except Exception as e:
        print(f"Error procesando email con GPT: {str(e)}")
        return {
            "Monto": 0,
            "Fecha": datetime.now().strftime("%Y-%m-%d"),
            "Categoria": "DESCONOCIDO",
            "Moneda": "DESCONOCIDO",
            "Lugar": "ERROR",
            "Status": "RECHAZADA",
            "Error": str(e)
        }

async def save_transaction_to_db(
    db: Session,
    transaction_data: Dict,
    dispositivo_id: int,
    category_id: Optional[int] = None
) -> bool:
    """
    Guarda la transacción en la base de datos si el status es 'APROBADA'.
    Retorna True si se guardó correctamente, False en caso contrario.
    """
    try:
        if transaction_data["Status"] != "APROBADA":
            print(f"Transacción no guardada por status: {transaction_data['Status']}")
            return False

        # Obtener el dispositivo para obtener el user_id
        dispositivo = db.query(Dispositivo).filter(Dispositivo.id == dispositivo_id).first()
        if not dispositivo:
            print(f"Dispositivo no encontrado: {dispositivo_id}")
            return False

        # Crear nueva transacción
        nueva_transaccion = Transaccion(
            user_id=dispositivo.id,
            category_id=transaction_data["Categoria"] ,  # Categoría por defecto si no se especifica
            account_id=1,  # Se podría mejorar para determinar la cuenta correcta
            #TODO: revisar si es correcto el formato de la fecha
            date=datetime.strptime(transaction_data["Fecha"], "%Y-%m-%d"),
            amount=float(transaction_data["Monto"]),
            type="GASTO",  # Se podría mejorar para determinar si es gasto o ingreso
            # note=f"Transacción en {transaction_data['Lugar']} - {transaction_data['Moneda']}",
            created_at=datetime.utcnow(),
            lugar=transaction_data["Lugar"],
            Tipomoneda=transaction_data["Moneda"]
        )

        #TODO: ahora no se guarda en la base de datos del server, se guarda en la base de datos de la app, por lo que no se necesita hacer commit
        # db.add(nueva_transaccion)
        # db.commit()
        return True

    except Exception as e:
        print(f"Error guardando transacción en la base de datos: {str(e)}")
        db.rollback()
        return False

async def process_and_save_email(
    db: Session,
    email_content: str,
    dispositivo_id: int,
    category_id: Optional[int] = None
) -> Dict:
    """
    Función principal que coordina el procesamiento del email y el guardado en la base de datos.
    """
    try:
        # Procesar el email con GPT
        transaction_data = await process_email_with_gpt(email_content)
        
        # Si el status es APROBADA, guardar en la base de datos
        if transaction_data["Status"] == "APROBADA":
            success = await save_transaction_to_db(
                db=db,
                transaction_data=transaction_data,
                dispositivo_id=dispositivo_id,
                category_id=category_id
            )
            if not success:
                transaction_data["Status"] = "RECHAZADA"
                transaction_data["Error"] = "Error al guardar en la base de datos"
        
        return transaction_data

    except Exception as e:
        print(f"Error en el procesamiento del email: {str(e)}")
        return {
            "Monto": 0,
            "Fecha": datetime.now().strftime("%Y-%m-%d"),
            "Moneda": "DESCONOCIDO",
            "Lugar": "ERROR",
            "Status": "RECHAZADA",
            "Error": str(e)
        } 