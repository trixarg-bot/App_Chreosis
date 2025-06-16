import 'package:chreosis_app/db/database_helper.dart';
import 'package:chreosis_app/models/usuario.dart';

class UsuarioRepository {

  // Agrega un nuevo usuario
  Future<void> addUsuario(Usuario usuario) async {
    await DatabaseHelper.instance.insertUsuario(usuario);
  }

  // Actualiza un usuario
  Future<void> getUsuario(String name) async {
    await DatabaseHelper.instance.getUsuarioByName(name);
  }

  Future<void> actualizarUsuario(Usuario usuario) async {
    await DatabaseHelper.instance.updateUsuario(usuario);
  }

  // Elimina un usuario
  Future<Usuario?> getUsuarioById(int id) async {
    return await DatabaseHelper.instance.getUsuarioById(id);
  }

  // Obtiene el saldo total de un usuario
  Future<double> getSaldoTotal(int id) async {
    return await DatabaseHelper.instance.getSaldoTotal(id);
  }

  // Verifica si existe un usuario
  Future<bool> existsUsuario(String name) async {
    return await DatabaseHelper.instance.existsUsuario(name);
  }
}