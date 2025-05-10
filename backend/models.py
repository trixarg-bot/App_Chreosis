from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    phone_number = Column(String)
    password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class Cuenta(Base):
    __tablename__ = "cuentas"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    name = Column(String, nullable=False)
    type = Column(String)
    amount = Column(Float, default=0)
    __table_args__ = (UniqueConstraint('user_id', 'name'),)

class Categoria(Base):
    __tablename__ = "categorias"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False)
    __table_args__ = (UniqueConstraint('user_id', 'name'),)

class Transaccion(Base):
    __tablename__ = "transacciones"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categorias.id"), nullable=False)
    account_id = Column(Integer, ForeignKey("cuentas.id"), nullable=False)
    date = Column(DateTime, nullable=False)
    amount = Column(Float, nullable=False)
    type = Column(String, nullable=False)
    note = Column(String)
    attachment = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)