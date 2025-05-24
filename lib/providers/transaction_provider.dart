
import 'package:flutter/material.dart';
import '../repositories/transaccion_repository.dart';
import '../models/transaccion.dart';

import '../repositories/usuario_repository.dart';
import '../repositories/cuenta_repository.dart';
import '../models/cuenta.dart';

class TransactionProvider extends ChangeNotifier {
 
 final UsuarioRepository usuarioRepository; 
 final CuentaRepository cuentaRepository;
 final TransaccionRepository repository;
 List<Transaccion> transacciones = [];
 bool isLoading = false;

 TransactionProvider({required this.repository, required this.usuarioRepository, required this.cuentaRepository});

 // Carga las transacciones del usuario
 Future<void> cargarTransacciones(int userId) async {
  transacciones = await repository.getTransacciones(userId);
  // Ordenar las transacciones por fecha de creación (más reciente primero)
  transacciones.sort((a, b) => 
      DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));
  notifyListeners();
 }

// Agrega una nueva transacción
 Future<void> agregarTransaccion(Transaccion transaccion) async {

  final cuenta = await cuentaRepository.getCuentaById(transaccion.accountId);
  if (transaccion.type == 'gasto' && cuenta != null && transaccion.amount > cuenta.amount) {
    return;
  }
  if (cuenta != null) {
    double nuevoMonto = cuenta.amount;
    if (transaccion.type == 'gasto') {
      nuevoMonto -= transaccion.amount;
    } else {
      nuevoMonto += transaccion.amount;
    }
    await cuentaRepository.updateCuenta(Cuenta(
      id: cuenta.id,
      userId: cuenta.userId,
      name: cuenta.name,
      type: cuenta.type,
      amount: nuevoMonto,
    ));
  }
  await repository.agregarTransaccion(transaccion);
  await cargarTransacciones(transaccion.userId);
  notifyListeners();
 }

// Actualiza una transacción
 Future<void> updateTransaccion(Transaccion transaccion) async {

  await repository.updateTransaccion(transaccion);
  await cargarTransacciones(transaccion.userId);

  isLoading = false;
  notifyListeners();
 }

// Elimina una transacción
 Future<void> deleteTransaccion(int id, int userId,) async {

  await repository.deleteTransaccion(id, userId);
  await cargarTransacciones(userId);
  isLoading = false;
  notifyListeners();
 }

}
