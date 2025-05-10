from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Usuario, Transaccion, Cuenta, Categoria
from dependencies import get_current_user
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

router = APIRouter(prefix="/transacciones", tags=["Transacciones"])

class TransaccionCreate(BaseModel):
    user_id: Optional[int] = None
    category_id: int
    account_id: int
    date: Optional[datetime] = None
    amount: float
    type: str
    note: Optional[str] = None
    attachment: Optional[str] = None

class TransaccionUpdate(BaseModel):
    category_id: Optional[int] = None
    account_id: Optional[int] = None
    date: Optional[datetime] = None
    amount: Optional[float] = None
    type: Optional[str] = None
    note: Optional[str] = None
    attachment: Optional[str] = None

class TransaccionDetalleOut(BaseModel):
    id: int
    account_name: str
    category_name: str
    user_name: str
    date: datetime
    amount: float
    type: str
    note: Optional[str] = None
    attachment: Optional[str] = None

class TransaccionOut(BaseModel):
    id: int
    user_id: Optional[int] = None
    category_id: int
    account_id: int
    date: datetime
    amount: float
    type: str
    note: Optional[str] = None
    attachment: Optional[str] = None
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str



@router.post("/", response_model=TransaccionOut)
def crear_transaccion(transaccion: TransaccionCreate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    # Buscar la cuenta asociada
    cuenta = db.query(Cuenta).filter(Cuenta.id == transaccion.account_id, Cuenta.user_id == current_user.id).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")
    # Actualizar el balance según el tipo de transacción
    if transaccion.type == "gasto":
        if cuenta.amount < transaccion.amount:
            raise HTTPException(status_code=400, detail="Fondos insuficientes")
        cuenta.amount -= transaccion.amount
    elif transaccion.type == "ingreso":
        cuenta.amount += transaccion.amount

    #Asingar fecha actual si no se envio en la peticion
    transaccion_data = transaccion.model_dump()
    if not transaccion_data.get("date"):
        transaccion_data["date"] = datetime.now()

    # Guardar la transacción
    nueva_transaccion = Transaccion(**transaccion_data)
    nueva_transaccion.user_id = current_user.id
    db.add(nueva_transaccion)
    db.commit()
    db.refresh(nueva_transaccion)
    db.refresh(cuenta)  # Para obtener el nuevo balance actualizado

    return nueva_transaccion

# @router.get("/", response_model=List[TransaccionOut])
# def listar_transacciones(db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
#     """
#     Ejemplo de endpoint protegido: solo usuarios autenticados pueden ver la lista.
#     """
#     return db.query(Transaccion).filter(Transaccion.user_id == current_user.id).all()

@router.get("/", response_model=List[TransaccionDetalleOut])
def listar_transacciones_detalle(db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    transacciones = (
        db.query(
            Transaccion.id,
            Cuenta.name.label("account_name"),
            Categoria.name.label("category_name"),
            Usuario.name.label("user_name"),
            Transaccion.date,
            Transaccion.amount,
            Transaccion.type,
            Transaccion.note,
            Transaccion.attachment
        )
        .join(Cuenta, Transaccion.account_id == Cuenta.id)
        .join(Categoria, Transaccion.category_id == Categoria.id)
        .join(Usuario, Transaccion.user_id == Usuario.id)
        .filter(Transaccion.user_id == current_user.id)
        .all()
    )
    # Convertir resultados a dicts para Pydantic
    return [TransaccionDetalleOut(**t._asdict()) for t in transacciones]

@router.get("/{transaccion_id}", response_model=TransaccionOut)
def obtener_transaccion(transaccion_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    transaccion = db.query(Transaccion).filter(Transaccion.id == transaccion_id, Transaccion.user_id == current_user.id).first()
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    return transaccion

@router.delete("/{transaccion_id}", status_code=200)
def eliminar_transaccion(transaccion_id: int, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    transaccion = db.query(Transaccion).filter(
        Transaccion.id == transaccion_id,
        Transaccion.user_id == current_user.id
    ).first()
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")

    cuenta = db.query(Cuenta).filter(
        Cuenta.id == transaccion.account_id,
        Cuenta.user_id == current_user.id
    ).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")

    # Revertir el efecto de la transacción
    if transaccion.type == "gasto":
        cuenta.amount += transaccion.amount
    elif transaccion.type == "ingreso":
        cuenta.amount -= transaccion.amount

    db.delete(transaccion)
    db.commit()
    return {"detail": "Transacción eliminada exitosamente"}

@router.put("/{transaccion_id}", response_model=TransaccionOut)
def actualizar_transaccion(transaccion_id: int, transaccion_actualizada: TransaccionUpdate, db: Session = Depends(get_db), current_user: Usuario = Depends(get_current_user)):
    transaccion = db.query(Transaccion).filter(
        Transaccion.id == transaccion_id,
        Transaccion.user_id == current_user.id
    ).first()
    if not transaccion:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")

    cuenta = db.query(Cuenta).filter(
        Cuenta.id == transaccion.account_id,
        Cuenta.user_id == current_user.id
    ).first()
    if not cuenta:
        raise HTTPException(status_code=404, detail="Cuenta no encontrada")

    # Revertir el efecto anterior
    if transaccion.type == "gasto":
        cuenta.amount += transaccion.amount
    elif transaccion.type == "ingreso":
        cuenta.amount -= transaccion.amount

    update_data = transaccion_actualizada.model_dump(exclude_unset=True)

    # Si se cambia la cuenta, debes revertir en la cuenta vieja y aplicar en la nueva (lógica adicional)
    nueva_cuenta = cuenta
    if "account_id" in update_data and update_data["account_id"] != transaccion.account_id:
        nueva_cuenta = db.query(Cuenta).filter(
            Cuenta.id == update_data["account_id"],
            Cuenta.user_id == current_user.id
        ).first()
        if not nueva_cuenta:
            raise HTTPException(status_code=404, detail="Nueva cuenta no encontrada")

    # Actualizar los campos de la transacción
    for key, value in update_data.items():
        setattr(transaccion, key, value)

    # Aplicar el nuevo efecto
    tipo = update_data.get("type", transaccion.type)
    monto = update_data.get("amount", transaccion.amount)
    if tipo == "gasto":
        if nueva_cuenta.amount < monto:
            raise HTTPException(status_code=400, detail="Fondos insuficientes")
        nueva_cuenta.amount -= monto
    elif tipo == "ingreso":
        nueva_cuenta.amount += monto

    db.commit()
    db.refresh(transaccion)
    db.refresh(nueva_cuenta)
    return transaccion