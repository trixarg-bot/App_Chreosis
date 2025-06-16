from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base, get_db
from routers import usuario, cuenta, categoria, transaccion, serviceEmail, devices

# Crear la base de datos si no existe
# Base.metadata.create_all(bind=engine)

# Instancia principal de la app
app = FastAPI(title="Chreosis API - Control de Gastos")

#! Configuración de CORS (por ahora abierta para desarrollo) tiene que cambiar para produccion
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas (routers) organizados
app.include_router(usuario.router)
app.include_router(cuenta.router)
app.include_router(categoria.router)
app.include_router(transaccion.router)
app.include_router(serviceEmail.router)
app.include_router(devices.router)


