import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from urllib.parse import quote_plus

# Cargar variables de entorno desde .env
# load_dotenv()

# Ruta absoluta al archivo .env
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

# Configuración de la conexión a la base de datos
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = 1433
DB_NAME = os.getenv("DB_NAME")
DB_DRIVER = os.getenv("DB_DRIVER")
DB_TRUST_SERVER_CERTIFICATE = os.getenv("DB_TRUST_SERVER_CERTIFICATE")

encoded_password = quote_plus(DB_PASSWORD)

# DB_USER = DB_USERNAME
# DB_PASSWORD = DB_PASSWORD
# DB_HOST = DB_SERVER
# DB_NAME = DB_NAME
# DB_DRIVER = "ODBC+Driver+18+for+SQL+Server"
# DB_TRUST_SERVER_CERTIFICATE = "yes"


# Construir la URL de conexión para SQL Server con pyodbc
SQLALCHEMY_DATABASE_URL = (
    f"mssql+pyodbc://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    f"?driver={DB_DRIVER.replace(' ', '+')}"
    f"&TrustServerCertificate={DB_TRUST_SERVER_CERTIFICATE}"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()