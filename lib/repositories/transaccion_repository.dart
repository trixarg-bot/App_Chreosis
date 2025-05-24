import 'package:chreosis_app/db/database_helper.dart';
import 'package:chreosis_app/models/transaccion.dart';

class TransaccionRepository {
 
 // Obtiene todas las transacciones de un usuario
 Future<List<Transaccion>> getTransacciones(int userId) async {
  return await DatabaseHelper.instance.getTransacciones(userId);
 }

 
// Agrega una nueva transacción
 Future<void> agregarTransaccion(Transaccion transaccion) async {
  await DatabaseHelper.instance.insertTransaccion(transaccion);
 }

 
// Actualiza una transacción
 Future<void> updateTransaccion(Transaccion transaccion) async {
  await DatabaseHelper.instance.updateTransaccion(transaccion);
 }

 
// Elimina una transacción
 Future<void> deleteTransaccion(int id, int userId) async {
  await DatabaseHelper.instance.deleteTransaccion(id, userId);
 }
}