import 'package:flutter/material.dart';
import '../repositories/usuario_repository.dart';
import '../models/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioRepository repository;
  double saldoTotal = 0.0;
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  UsuarioProvider({required this.repository});

  // Obtiene el saldo total de un usuario
  Future<void> getSaldoTotal(int id) async {
   saldoTotal = await repository.getSaldoTotal(id);   
   notifyListeners();
  }

  // Agrega un nuevo usuario
  Future<void> addUsuario(Usuario usuario) async {
    await repository.addUsuario(usuario);
    notifyListeners();
  }

  // Verifica si existe un usuario
  Future<bool> existsUsuario(String name) async {
    return await repository.existsUsuario(name);
  }

  // Establece el usuario actual
  void setUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  // Cierra la sesión del usuario
  void logout() {
    _usuario = null;
    notifyListeners();
  }


  
}