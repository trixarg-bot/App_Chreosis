import 'package:flutter/material.dart';
import 'package:chreosis_app/models/cuenta.dart';
import '../repositories/cuenta_repository.dart';

class CuentaProvider extends ChangeNotifier {
  final CuentaRepository repository;
  List<Cuenta> cuentas = [];
  bool isLoading = false;

  CuentaProvider({required this.repository});

  //obtener cuentas
  Future<void> cargarCuentas(int userId) async {
    isLoading = true;
    cuentas = await repository.getCuentas(userId);
    isLoading = false;
    notifyListeners();
  }

  //agregar cuenta
  Future<void> agregarCuenta({required int userId, required String name, required String type, required double amount, required String moneda}) async {
    
    final cuenta = Cuenta(
      userId: userId,
      name: name,
      type: type,
      amount: amount,
      moneda: moneda
    );
    await repository.agregarCuenta(cuenta);
    await cargarCuentas(userId);
    notifyListeners();
  }

  //actualizar cuenta
  //TODO: DESPUES no ahora CAMBIAR PARA QUE AL ACTUALIZAR SE CARGUE LA LISTA DE CUENTAS.
  Future<void> actualizarCuenta(Cuenta cuenta) async {
    await repository.updateCuenta(cuenta);
    cuentas =
        cuentas.map((c) => c.id == cuenta.id ? cuenta : c).toList();
    notifyListeners();
  }

  //eliminar cuenta
  Future<void> eliminarCuenta(int id) async {
    await repository.deleteCuenta(id);
    cuentas.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
