import 'package:chreosis_app/services/api_currency_service.dart';
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
 final ApiCurrencyService currencyService;
 List<Transaccion> transacciones = [];
 bool isLoading = false;

 TransactionProvider({required this.repository, required this.usuarioRepository, required this.cuentaRepository, required this.currencyService});

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
    if (cuenta == null) return; // No se puede procesar sin una cuenta

    double montoAfectado = transaccion.amount;
    Transaccion transaccionFinal = transaccion;

    // 1. Verificar si se necesita conversión
    if (transaccion.conversion) {
      try {
        // 2. Obtener la tasa de cambio
        final tasaCambio = await currencyService.convertCurrency(
          fromCurrency: transaccion.moneda,
          toCurrency: cuenta.moneda,
          amount: transaccion.amount,
        );

        if (tasaCambio != null) {
          // 3. El monto afectado es el resultado de la conversión
          montoAfectado = tasaCambio;

          // 4. Actualizar el objeto Transaccion con el monto convertido
          transaccionFinal = transaccion.copyWith(
            montoConvertido: montoAfectado,
          );
        } else {
          // Manejar el caso de error donde no se pudo obtener la tasa
          // Por ahora, no se hará la transacción para evitar inconsistencias
          print(
            "Error: No se pudo obtener la tasa de cambio. Transacción cancelada.",
          );
          return;
        }
      } catch (e) {
        print("Error durante la conversión de moneda: $e");
        return; // Salir si hay un error en la API
      }
    }

    // Lógica para verificar fondos (usando el monto que realmente afecta la cuenta)
    if (transaccion.type == 'gasto' && montoAfectado > cuenta.amount) {
      // Opcional: podrías lanzar una excepción o notificar al usuario de fondos insuficientes
      print("Error: Fondos insuficientes para realizar la transacción.");
      return;
    }

    // 5. Actualizar el saldo de la cuenta
    double nuevoMontoCuenta = cuenta.amount;
    if (transaccion.type == 'gasto') {
      nuevoMontoCuenta -= montoAfectado;
    } else {
      nuevoMontoCuenta += montoAfectado;
    }

    await cuentaRepository.updateCuenta(
      cuenta.copyWith(amount: nuevoMontoCuenta),
    );

    // 6. Guardar la transacción final en la base de datos
    await repository.agregarTransaccion(transaccionFinal);

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
