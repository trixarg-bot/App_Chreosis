from fastapi import APIRouter, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import get_db
from models import Cuenta, Usuario
from utils.security import hash_password, verify_password, create_access_token
from dependencies import get_current_user
from pydantic import BaseModel, EmailStr, Field, validator
from typing import List, Optional
from jose import JWTError


# OAuth2PasswordBearer es el esquema estándar para obtener el token JWT desde el header Authorization


router = APIRouter(prefix="/cuentas", tags=["Cuentas"])

class CuentaCreate(BaseModel):
    user_id: Optional[int] = None
    name: str
    type: str
    amount: float

class CuentaUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    amount: Optional[float] = None

class CuentaOut(BaseModel):
    id: int
    user_id: int
    name: str
    type: str
    amount: float
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str



@router.post("/", response_model=CuentaOut)
def crear_cuenta(cuenta: CuentaCreate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    db_cuenta = db.query(Cuenta).filter(Cuenta.name == cuenta.name, Cuenta.user_id == current_user.id).first()
    if db_cuenta:
        raise HTTPException(status_code=400, detail="Cuenta ya registrada con el mismo nombre.")
    nuevo = Cuenta(**cuenta.model_dump())
    nuevo.user_id = current_user.id
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

@router.get("/", response_model=List[CuentaOut])
def listar_cuentas(db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Ejemplo de endpoint protegido: solo usuarios autenticados pueden ver la lista.
    """
    return db.query(Cuenta).filter(Cuenta.user_id == current_user.id).all()

@router.get("/{cuenta_id}", response_model=CuentaOut)
def obtener_cuenta(cuenta_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    cuenta = db.query(Cuenta).filter(Cuenta.id == cuenta_id, Cuenta.user_id == current_user.id).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
    return cuenta

@router.delete("/{cuenta_id}", status_code=200)
def eliminar_cuenta(cuenta_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    cuenta = db.query(Cuenta).filter(Cuenta.id == cuenta_id, Cuenta.user_id == current_user.id).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
    db.delete(cuenta)
    db.commit()
    return {"detail": "Cuenta eliminada exitosamente"}

@router.put("/{cuenta_id}", response_model=CuentaOut)
def actualizar_cuenta(cuenta_id: int, cuenta_actualizada: CuentaUpdate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Actualiza una cuenta existente.

    Args:
    - cuenta_id (int): El ID de la cuenta a actualizar.
    - cuenta_actualizada (CuentaUpdate): Un objeto con los campos a actualizar.

    Returns:
    - CuentaOut: La cuenta actualizada.

    Raises:
    - HTTPException: Si la cuenta no existe.
    """
    cuenta = db.query(Cuenta).filter(Cuenta.id == cuenta_id, Cuenta.user_id == current_user.id).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
    update_data = cuenta_actualizada.model_dump(exclude_unset=True)
    # Validar que el nuevo nombre no esté en uso.
    if "name" in update_data and update_data["name"] != cuenta.name:
        name_existente = db.query(Cuenta).filter(Cuenta.name == update_data["name"], Cuenta.user_id == current_user.id).first()
        if name_existente:
            raise HTTPException(status_code=400, detail="Nombre de cuenta ya registrado.")
    for key, value in update_data.items():
        setattr(cuenta, key, value)
    db.commit()
    db.refresh(cuenta)
    return cuenta