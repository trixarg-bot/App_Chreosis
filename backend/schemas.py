from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DispositivoBase(BaseModel):
    nombre_dispositivo: Optional[str] = None
    fcm_token: str

class DispositivoCreate(DispositivoBase):
    pass

class DispositivoResponse(DispositivoBase):
    id: int
    ultimo_acceso: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True 