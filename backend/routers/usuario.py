from fastapi import APIRouter, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import get_db
from models import Usuario
from utils.security import hash_password, verify_password, create_access_token
from dependencies import get_current_user
from pydantic import BaseModel, EmailStr, Field, validator
from typing import List, Optional
from jose import JWTError

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

class UsuarioCreate(BaseModel):
    name: str
    email: EmailStr
    phone_number: str | None = None
    password: str = Field(..., min_length=8, max_length=20)

    @validator('password')
    def password_strength(cls, v):
        if not any(c.isdigit() for c in v):
            raise ValueError('La contraseña debe contener al menos un número')
        if not any(c.isupper() for c in v):
            raise ValueError('La contraseña debe contener al menos una mayúscula')
        return v

class UsuarioUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone_number: Optional[str] = None

class UsuarioOut(BaseModel):
    id: int
    name: str
    email: str
    phone_number: str | None
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str



@router.post("/", response_model=UsuarioOut)
def crear_usuario(usuario: UsuarioCreate, db: Session = Depends(get_db)):
    db_user = db.query(Usuario).filter(Usuario.email == usuario.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email ya registrado")
    nuevo = Usuario(**usuario.model_dump())
    nuevo.password = hash_password(nuevo.password)
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Endpoint de login:
    - Recibe email y password.
    - Verifica credenciales.
    - Si son correctas, retorna un JWT.
    """
    user = db.query(Usuario).filter(Usuario.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    # Creamos el JWT con el id y email del usuario
    access_token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/", response_model=List[UsuarioOut])
def listar_usuarios(db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Ejemplo de endpoint protegido: solo usuarios autenticados pueden ver la lista.
    """
    return db.query(Usuario).all()

@router.get("/{usuario_id}", response_model=UsuarioOut)
def obtener_usuario(usuario_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return usuario

@router.delete("/{usuario_id}", status_code=200)
def eliminar_usuario(usuario_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    db.delete(usuario)
    db.commit()
    return {"detail": "Usuario eliminado exitosamente"}

@router.put("/{usuario_id}", response_model=UsuarioOut)
def actualizar_usuario(usuario_id: int, usuario_actualizado: UsuarioUpdate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Actualiza un usuario existente.

    Args:
    - usuario_id (int): El ID del usuario a actualizar.
    - usuario_actualizado (UsuarioCreate): Un objeto con los campos a actualizar.

    Returns:
    - UsuarioOut: El usuario actualizado.

    Raises:
    - HTTPException: Si el usuario no existe.
    """
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    update_data = usuario_actualizado.model_dump(exclude_unset=True)
    # Validar que el nuevo email no esté en uso por otro usuario
    if "email" in update_data and update_data["email"] != usuario.email:
        email_existente = db.query(Usuario).filter(Usuario.email == update_data["email"], Usuario.id != usuario_id).first()
        if email_existente:
            raise HTTPException(status_code=400, detail="Email ya registrado por otro usuario")
    for key, value in update_data.items():
        setattr(usuario, key, value)
    db.commit()
    db.refresh(usuario)
    return usuario