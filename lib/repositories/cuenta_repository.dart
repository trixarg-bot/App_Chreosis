import 'package:chreosis_app/db/database_helper.dart';
import 'package:chreosis_app/models/cuenta.dart';

class CuentaRepository {
  
  // Obtiene todas las cuentas de un usuario
  Future<List<Cuenta>> getCuentas(int userId) async {
    return await DatabaseHelper.instance.getCuentasByUser(userId);
  }

  // Obtiene una cuenta por ID
  Future<Cuenta?> getCuentaById(int id) async {
    return await DatabaseHelper.instance.getCuentaById(id);
  }

  // Agrega una nueva cuenta
  Future<void> agregarCuenta(Cuenta cuenta) async {
    await DatabaseHelper.instance.insertCuenta(cuenta);

  }

  // Actualiza una cuenta
  Future<void> updateCuenta(Cuenta cuenta) async {
    await DatabaseHelper.instance.updateCuenta(cuenta);
  }

  // Elimina una cuenta
  Future<void> deleteCuenta(int id) async {
    await DatabaseHelper.instance.deleteCuenta(id);
  }

}
