from fastapi import APIRouter, Depends, HTTPException, status, Security
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from database import get_db
from models import Cuenta, Categoria, Usuario
from utils.security import hash_password, verify_password, create_access_token
from dependencies import get_current_user
from pydantic import BaseModel, EmailStr, Field, validator
from typing import List, Optional
from jose import JWTError


# OAuth2PasswordBearer es el esquema estándar para obtener el token JWT desde el header Authorization


router = APIRouter(prefix="/categorias", tags=["Categorias"])

class CategoriaCreate(BaseModel):
    user_id: Optional[int] = None
    name: str
    type: str

class CategoriaUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None

class CategoriaOut(BaseModel):
    id: int
    user_id: int
    name: str
    type: str
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str



@router.post("/", response_model=CategoriaOut)
def crear_categoria(categoria: CategoriaCreate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    db_categoria = db.query(Categoria).filter(Categoria.name == categoria.name, Categoria.user_id == current_user.id).first()
    if db_categoria:
        raise HTTPException(status_code=400, detail="Categoría ya registrada con el mismo nombre.")
    nuevo = Categoria(**categoria.model_dump())
    nuevo.user_id = current_user.id
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

@router.get("/", response_model=List[CategoriaOut])
def listar_categorias(db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Ejemplo de endpoint protegido: solo usuarios autenticados pueden ver la lista.
    """
    return db.query(Categoria).filter(Categoria.user_id == current_user.id).all()

@router.get("/{categoria_id}", response_model=CategoriaOut)
def obtener_categoria(categoria_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    categoria = db.query(Categoria).filter(Categoria.id == categoria_id, Categoria.user_id == current_user.id).first()
    if not categoria:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    return categoria

@router.delete("/{categoria_id}", status_code=200)
def eliminar_categoria(categoria_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    categoria = db.query(Categoria).filter(Categoria.id == categoria_id, Categoria.user_id == current_user.id).first()
    if not categoria:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    db.delete(categoria)
    db.commit()
    return {"detail": "Categoría eliminada exitosamente"}

@router.put("/{categoria_id}", response_model=CategoriaOut)
def actualizar_categoria(categoria_id: int, categoria_actualizada: CategoriaUpdate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    """
    Actualiza una categoría existente.

    Args:
    - categoria_id (int): El ID de la categoría a actualizar.
    - categoria_actualizada (CategoriaUpdate): Un objeto con los campos a actualizar.

    Returns:
    - CategoriaOut: La categoría actualizada.

    Raises:
    - HTTPException: Si la categoría no existe.
    """
    categoria = db.query(Categoria).filter(Categoria.id == categoria_id, Categoria.user_id == current_user.id).first()
    if not categoria:
        raise HTTPException(status_code=404, detail="Categoría no encontrada")
    update_data = categoria_actualizada.model_dump(exclude_unset=True)
    # Validar que el nuevo nombre no esté en uso.
    if "name" in update_data and update_data["name"] != categoria.name:
        name_existente = db.query(Categoria).filter(Categoria.name == update_data["name"], Categoria.user_id == current_user.id).first()
        if name_existente:
            raise HTTPException(status_code=400, detail="Nombre de categoría ya registrado.")
    for key, value in update_data.items():
        setattr(categoria, key, value)
    db.commit()
    db.refresh(categoria)
    return categoria