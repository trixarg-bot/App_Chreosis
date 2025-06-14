from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from database import get_db
from models import Dispositivo
from schemas import DispositivoCreate, DispositivoResponse

router = APIRouter(prefix="/devices", tags=["devices"])

@router.post("/register", response_model=DispositivoResponse)
async def register_device(
    device: DispositivoCreate,
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