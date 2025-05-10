// import 'package:chreosis_app/utils/app_loger.dart';
// import '../database_helper.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';


// Future<int> getDatabaseVersion() async {
//   final db = await DatabaseHelper.instance.database;
//   final result = await db.rawQuery('PRAGMA user_version');
//   final version = result.first.values.first as int;
//   return version;
// }


// Future<void> runTests() async {
//   final db = await DatabaseHelper.instance.database;

//   // Limpia las tablas para un test limpio
//   await db.delete('transacciones');
//   logger.i('Transacciones limpiadas');
//   await db.delete('categorias');
//   logger.i('Categorias limpiadas');
//   await db.delete('cuentas');
//   logger.i('Cuentas limpiadas');
//   await db.delete('usuarios');
//   logger.i('Usuarios limpiados');

// }
