import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../repositories/categoria_repository.dart';

class CategoriaProvider extends ChangeNotifier {
  
  final CategoriaRepository repository;
  bool isLoading = false;
  List<Categoria> categorias = [];
  List<Categoria> _todasLasCategorias =
      []; // Lista completa incluyendo 'sin categorizar'
  CategoriaProvider({required this.repository});

  // Carga las categorías del usuario
  Future<void> cargarCategorias(int userId) async {
    _todasLasCategorias = await repository.getCategorias(userId);
    categorias =
        _todasLasCategorias
            .where((cat) => cat.name.toLowerCase() != 'sin categorizar')
            .toList();
    notifyListeners();
  }

  // Obtiene todas las categorías incluyendo 'sin categorizar' (para uso interno)
  List<Categoria> getTodasLasCategorias() {
    return _todasLasCategorias;
  }

  // Obtiene una categoría específica por ID (incluyendo 'sin categorizar')
  Categoria? getCategoriaById(int id) {
    try {
      return _todasLasCategorias.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // Agrega una nueva categoría
  Future<void> insertCategoria({required int userId, required String name, required String type, required int iconCode}) async {
    isLoading = true;
    notifyListeners();
    final categoria = Categoria(
    userId: userId, 
    name: name, 
    type: type, 
    iconCode: iconCode);
    await repository.insertCategoria(categoria);
    await cargarCategorias(categoria.userId);
    isLoading = false;
    notifyListeners();
  }

  // Actualiza una categoría
  Future<void> updateCategoria(Categoria categoria) async {
    isLoading = true;
    notifyListeners();
    await repository.updateCategoria(categoria);
    await cargarCategorias(categoria.userId);
    isLoading = false;
    notifyListeners();
  }

  // Elimina una categoría
  Future<void> deleteCategoria(int id, int userId) async {
    isLoading = true;
    notifyListeners();
    await repository.deleteCategoria(id, userId);
    await cargarCategorias(userId);
    isLoading = false;
    notifyListeners();
  }
}
