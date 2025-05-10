import pytest
import logging
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

# Configura logging para que los mensajes salgan en pytest y report.html
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

USER_EMAIL = "admin@admin.com"  # Cambia por el email real del user_id=6
USER_PASSWORD = "Admin12345"    # Cambia por la contraseña real

CUENTA_ID = 1  # Cuenta de ahorro, user_id=6
CUENTA_INGRESOS_ID = 4  # Cuenta ingresos, user_id=6
CATEGORIA_ENTRETENIMIENTO = 3  # Gasto
CATEGORIA_PAGO_TRABAJO = 4     # Ingreso

@pytest.fixture
def auth_header():
    response = client.post("/usuarios/login", data={"username": USER_EMAIL, "password": USER_PASSWORD})
    assert response.status_code == 200
    token = response.json()["access_token"]
    logger.info("Login exitoso para usuario %s", USER_EMAIL)
    print(f"Login exitoso para usuario {USER_EMAIL}")
    return {"Authorization": f"Bearer {token}"}

# def test_gasto_y_actualizacion(auth_header):
#     logger.info("INICIO: Test de gasto y actualización")
#     print("INICIO: Test de gasto y actualización")

#     # 1. Crear un gasto de 2000 en Entretenimiento
#     data = {
#         "account_id": CUENTA_ID,
#         "category_id": CATEGORIA_ENTRETENIMIENTO,
#         "amount": 2000,
#         "type": "gasto"
#     }
#     response = client.post("/transacciones/", json=data, headers=auth_header)
#     assert response.status_code == 200
#     trans = response.json()
#     trans_id = trans["id"]
#     logger.info("Transacción creada: %s", trans)
#     print(f"Transacción creada: {trans}")

#     # 2. Verifica saldo (debe ser 30000 - 2000 = 28000)
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de gasto: %s", cuenta["amount"])
#     print(f"Saldo después de gasto: {cuenta['amount']}")
#     assert cuenta["amount"] == 28000

#     # 3. Actualizar el gasto a 5000
#     response = client.put(f"/transacciones/{trans_id}", json={"amount": 5000}, headers=auth_header)
#     assert response.status_code == 200
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de actualizar gasto a 5000: %s", cuenta["amount"])
#     print(f"Saldo después de actualizar gasto a 5000: {cuenta['amount']}")
#     assert cuenta["amount"] == 25000  # 30000 - 5000

#     # 4. Cambiar tipo a ingreso (deja el monto igual)
#     response = client.put(
#         f"/transacciones/{trans_id}",
#         json={"type": "ingreso", "category_id": CATEGORIA_PAGO_TRABAJO},
#         headers=auth_header
#     )
#     assert response.status_code == 200
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de cambiar tipo a ingreso: %s", cuenta["amount"])
#     print(f"Saldo después de cambiar tipo a ingreso: {cuenta['amount']}")
#     assert cuenta["amount"] == 35000  # 30000 + 5000

#     # 5. Eliminar la transacción (debe revertir el ingreso)
#     response = client.delete(f"/transacciones/{trans_id}", headers=auth_header)
#     assert response.status_code == 200
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de eliminar la transacción: %s", cuenta["amount"])
#     print(f"Saldo después de eliminar la transacción: {cuenta['amount']}")
#     assert cuenta["amount"] == 30000  # Vuelve al saldo original

#     logger.info("FIN: Test de gasto y actualización")
#     print("FIN: Test de gasto y actualización")

# def test_ingreso_y_cambio_de_categoria(auth_header):
#     logger.info("INICIO: Test de ingreso y cambio de categoría")
#     print("INICIO: Test de ingreso y cambio de categoría")

#     # 1. Crear un ingreso de 10000 con categoria PAGO TRABAJO
#     data = {
#         "account_id": CUENTA_ID,
#         "category_id": CATEGORIA_PAGO_TRABAJO,
#         "amount": 10000,
#         "type": "ingreso"
#     }
#     response = client.post("/transacciones/", json=data, headers=auth_header)
#     assert response.status_code == 200
#     trans = response.json()
#     trans_id = trans["id"]
#     logger.info("Transacción de ingreso creada: %s", trans)
#     print(f"Transacción de ingreso creada: {trans}")

#     # 2. Verifica saldo (debe ser 30000 + 10000 = 40000)
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de ingreso: %s", cuenta["amount"])
#     print(f"Saldo después de ingreso: {cuenta['amount']}")
#     assert cuenta["amount"] == 40000

#     # 3. Cambiar la categoría a "Entretenimiento" (tipo gasto y monto igual)
#     response = client.put(
#         f"/transacciones/{trans_id}",
#         json={"category_id": CATEGORIA_ENTRETENIMIENTO, "type": "gasto"},
#         headers=auth_header
#     )
#     assert response.status_code == 200
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de cambiar tipo a gasto: %s", cuenta["amount"])
#     print(f"Saldo después de cambiar tipo a gasto: {cuenta['amount']}")
#     assert cuenta["amount"] == 20000  # 30000 - 10000

#     # 4. Eliminar la transacción (debe revertir el gasto)
#     response = client.delete(f"/transacciones/{trans_id}", headers=auth_header)
#     assert response.status_code == 200
#     cuenta = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
#     logger.info("Saldo después de eliminar la transacción: %s", cuenta["amount"])
#     print(f"Saldo después de eliminar la transacción: {cuenta['amount']}")
#     assert cuenta["amount"] == 30000  # Vuelve al saldo anterior

#     logger.info("FIN: Test de ingreso y cambio de categoría")
#     print("FIN: Test de ingreso y cambio de categoría")

# def test_fondos_insuficientes(auth_header):
#     logger.info("INICIO: Test de fondos insuficientes")
#     print("INICIO: Test de fondos insuficientes")

#     # 1. Crear un gasto mayor al saldo usando Entretenimiento
#     data = {
#         "account_id": CUENTA_ID,
#         "category_id": CATEGORIA_ENTRETENIMIENTO,
#         "amount": 999999,
#         "type": "gasto"
#     }
#     response = client.post("/transacciones/", json=data, headers=auth_header)
#     logger.info("Respuesta a gasto mayor al saldo: %s", response.json())
#     print(f"Respuesta a gasto mayor al saldo: {response.json()}")
#     assert response.status_code == 400  # Fondos insuficientes

#     logger.info("FIN: Test de fondos insuficientes")
#     print("FIN: Test de fondos insuficientes")

def test_cambio_de_cuenta(auth_header):
    logger.info("INICIO: Test de cambio de cuenta")
    print("INICIO: Test de cambio de cuenta")

    # Obtener saldos iniciales
    cuenta_ahorro = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
    cuenta_ingresos = client.get(f"/cuentas/{CUENTA_INGRESOS_ID}", headers=auth_header).json()
    saldo_ahorro_inicial = cuenta_ahorro["amount"]
    saldo_ingresos_inicial = cuenta_ingresos["amount"]

    # 1. Crear un gasto de 100 en la cuenta de ahorro
    data = {
        "account_id": CUENTA_ID,
        "category_id": CATEGORIA_ENTRETENIMIENTO,
        "amount": 100,
        "type": "gasto"
    }
    response = client.post("/transacciones/", json=data, headers=auth_header)
    assert response.status_code == 200
    trans = response.json()
    trans_id = trans["id"]
    logger.info("Transacción creada en cuenta ahorro: %s", trans)
    print(f"Transacción creada en cuenta ahorro: {trans}")

    # 2. Verifica saldo de cuenta de ahorro
    cuenta_ahorro = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
    assert cuenta_ahorro["amount"] == saldo_ahorro_inicial - 100
    logger.info("Saldo cuenta ahorro tras gasto: %s", cuenta_ahorro["amount"])
    print(f"Saldo cuenta ahorro tras gasto: {cuenta_ahorro['amount']}")

    # 3. Mover la transacción a la cuenta de ingresos
    response = client.put(
        f"/transacciones/{trans_id}",
        json={"account_id": CUENTA_INGRESOS_ID},
        headers=auth_header
    )
    assert response.status_code == 200
    logger.info("Transacción movida a cuenta ingresos")
    print("Transacción movida a cuenta ingresos")

    # 4. Verifica saldos de ambas cuentas
    cuenta_ahorro = client.get(f"/cuentas/{CUENTA_ID}", headers=auth_header).json()
    cuenta_ingresos = client.get(f"/cuentas/{CUENTA_INGRESOS_ID}", headers=auth_header).json()
    assert cuenta_ahorro["amount"] == saldo_ahorro_inicial  # Se revierte el gasto
    assert cuenta_ingresos["amount"] == saldo_ingresos_inicial - 100  # Se aplica el gasto
    logger.info("Saldo cuenta ahorro tras mover: %s", cuenta_ahorro["amount"])
    logger.info("Saldo cuenta ingresos tras mover: %s", cuenta_ingresos["amount"])
    print(f"Saldo cuenta ahorro tras mover: {cuenta_ahorro['amount']}")
    print(f"Saldo cuenta ingresos tras mover: {cuenta_ingresos['amount']}")

    # 5. Eliminar la transacción (debe revertir el gasto en cuenta ingresos)
    response = client.delete(f"/transacciones/{trans_id}", headers=auth_header)
    assert response.status_code == 200
    cuenta_ingresos = client.get(f"/cuentas/{CUENTA_INGRESOS_ID}", headers=auth_header).json()
    assert cuenta_ingresos["amount"] == saldo_ingresos_inicial  # Vuelve al saldo original
    logger.info("Saldo cuenta ingresos tras eliminar transacción: %s", cuenta_ingresos["amount"])
    print(f"Saldo cuenta ingresos tras eliminar transacción: {cuenta_ingresos['amount']}")

    logger.info("FIN: Test de cambio de cuenta")
    print("FIN: Test de cambio de cuenta")