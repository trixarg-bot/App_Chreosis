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
    lugar = Column(String, default="DESCONOCIDO")
    Tipomoneda = Column(String, default="DESCONOCIDO")

class GmailToken(Base):
    __tablename__ = "gmail_tokens"
    id = Column(Integer, primary_key=True, index=True)
    dispositivo_id = Column(Integer, ForeignKey("dispositivos.id"), unique=True, nullable=False)
    access_token = Column(String, nullable=False)
    refresh_token = Column(String, nullable=False)
    token_uri = Column(String, nullable=False)
    client_id = Column(String, nullable=False)
    client_secret = Column(String, nullable=False)
    scopes = Column(String, nullable=False)
    expiration_date = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    #QUE ES ESTO DE RELATIONSHIP?
    dispositivo = relationship("Dispositivo", back_populates="gmail_token")

class Dispositivo(Base):
    __tablename__ = "dispositivos"
    id = Column(Integer, primary_key=True, index=True)
    fcm_token = Column(String, nullable=False)
    nombre_dispositivo = Column(String)
    ultimo_acceso = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    gmail_token = relationship("GmailToken", back_populates="dispositivo", uselist=False)