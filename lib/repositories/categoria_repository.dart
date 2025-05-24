import 'package:chreosis_app/db/database_helper.dart';
import 'package:chreosis_app/models/categoria.dart';

class CategoriaRepository {
  // Obtiene todas las categorías
 Future<List<Categoria>> getCategorias(int userId) async {
  return await DatabaseHelper.instance.getCategorias(userId);
 }

 // Agrega una nueva categoría
 Future<void> insertCategoria(Categoria categoria) async {
  await DatabaseHelper.instance.insertCategoria(categoria);
 }

 // Actualiza una categoría
 Future<void> updateCategoria(Categoria categoria) async {
  await DatabaseHelper.instance.updateCategoria(categoria);
 }

 // Elimina una categoría
 Future<void> deleteCategoria(int id, int userId) async {
  await DatabaseHelper.instance.deleteCategoria(id, userId);
 }
}