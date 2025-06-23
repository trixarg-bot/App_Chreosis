import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// import 'package:chreosis_app/utils/app_loger.dart' as log;
import 'package:chreosis_app/models/cuenta.dart';
import 'package:chreosis_app/db/migrations_helper.dart';
import 'package:chreosis_app/models/usuario.dart';
import 'package:chreosis_app/models/transaccion.dart';
import 'package:chreosis_app/models/categoria.dart';
import 'package:chreosis_app/models/currency_config.dart';

// Clase singleton que gestiona toda la lógica de la base de datos
class DatabaseHelper {
  //! --- SOLO PARA USO DE DESARROLLO ---
  /// Borra todas las transacciones de la base de datos. Usar únicamente en desarrollo.
  Future<void> deleteAllTransacciones() async {
    final db = await instance.database;
    await db.delete('transacciones');
  }
  //! --- FIN SOLO DESARROLLO ---
  // Crea una única instancia de la clase (patrón Singleton)
  static final DatabaseHelper instance = DatabaseHelper._init();

  // Variable privada que almacenará la instancia de la base de datos abierta
  static Database? _database;

  // Constructor privado (solo se llama internamente)
  DatabaseHelper._init();

  // Getter asíncrono que retorna la base de datos si ya está abierta,
  // si no, la inicializa
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Si aún no existe, la inicializa con el nombre chreosis_finanzas.db
    _database = await _initDB('chreosis_finanzas.db');
    return _database!;
  }

  // Inicializa la base de datos: construye la ruta y la abre
  Future<Database> _initDB(String filePath) async {
    //* Obtiene el path del sistema donde se almacenan las bases de datos
    final dbPath = await getDatabasesPath();

    //* Une el path base con el nombre del archivo de la base de datos
    final path = join(dbPath, filePath);

    //* Abre la base de datos, y si no existe, ejecuta la función _createDB
    return await openDatabase(path, version: 7, onCreate: _createDB, onUpgrade: MigrationHelper.onUpgrade,);
  }

  //* Esta función se ejecuta SOLO la primera vez que se crea la base de datos
  //* Aquí se crean todas las tablas necesarias
  Future _createDB(Database db, int version) async {
    // Crea tabla de usuarios
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone_number TEXT,
        password TEXT NOT NULL,
        created_at TEXT
      );
    ''');

    // Crea tabla de cuentas (vinculadas a un usuario)
    await db.execute('''
        CREATE TABLE cuentas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT,
          amount REAL DEFAULT 0,
          moneda TEXT NOT NULL DEFAULT 'DOP',
          FOREIGN KEY (user_id) REFERENCES usuarios(id),
          UNIQUE(user_id, name)
        );
      ''');

    // Crea tabla de categorías (Ingreso o Gasto)
    await db.execute('''
        CREATE TABLE categorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT,
          icon_code INTEGER,
          FOREIGN KEY (user_id) REFERENCES usuarios(id),
          UNIQUE(user_id, name)
        );
      ''');
    //TODO: AGREGAR LUGAR A LA TABLA DE TRANSACCIONES
    // Crea tabla de transacciones (movimientos financieros)
    await db.execute('''
      CREATE TABLE transacciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        place TEXT,
        date TEXT,
        amount REAL,
        type TEXT,
        note TEXT,
        attachment TEXT,
        created_at TEXT,
        moneda TEXT NOT NULL,
        conversion INTEGER NOT NULL DEFAULT 0,
        monto_convertido REAL,
        FOREIGN KEY (user_id) REFERENCES usuarios (id),
        FOREIGN KEY (category_id) REFERENCES categorias (id),
        FOREIGN KEY (account_id) REFERENCES cuentas (id)
      );
    ''');
    // Crea tabla para la configuracion de divisas
    await db.execute('''
        CREATE TABLE currency_config (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          base_currency TEXT NOT NULL,
          preferred_currencies TEXT,
          last_updated TEXT,
          FOREIGN KEY (user_id) REFERENCES usuarios(id)
        );
      ''');
  }

  //** */ --- USUARIOS ---
  // Insertar nuevo usuario
  Future<int> insertUsuario(Usuario usuario) async {
    final db = await instance.database;
    return await db.insert('usuarios', usuario.toMap());
  }

  // Obtener usuario por nombre
  Future<Usuario?> getUsuarioByName(String name) async {
    final db = await instance.database;
    final result = await db.query('usuarios', where: 'name = ?', whereArgs: [name]);
    if (result.isNotEmpty) {
      return Usuario.fromMap(result.first);
    }
    return null;
  }

  // Obtener usuario por ID
  Future<Usuario?> getUsuarioById(int id) async {
    final db = await instance.database;
    final result = await db.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Usuario.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUsuario(Usuario usuario) async {
    final db = await instance.database;
    return await db.update('usuarios', usuario.toMap(), where: 'id = ?',whereArgs: [usuario.id],);
  }

  // Verificar si existe usuario (para registro/login)
  Future<bool> existsUsuario(String name) async {
    final db = await instance.database;
    final result = await db.query('usuarios', where: 'name = ?', whereArgs: [name]);
    return result.isNotEmpty;
  }

  //** */ --- CATEGORIAS ---
  // Obtener todas las categorías de un usuario
  Future<List<Categoria>> getCategorias(int userId) async {
    final db = await instance.database;
    final result = await db.query('categorias', where: 'user_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    return result.map((map) => Categoria.fromMap(map)).toList();
  }

  // Obtener una categoría por id
  Future<Categoria?> getCategoriaById(int id) async {
    final db = await instance.database;
    final result = await db.query('categorias', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Categoria.fromMap(result.first);
    }
    return null;
  }

  // Insertar nueva categoría
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await instance.database;
    return await db.insert('categorias', categoria.toMap());
  }

  // Actualizar una categoría
  Future<int> updateCategoria(Categoria categoria) async {
    final db = await instance.database;
    return await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  // Eliminar una categoría
  Future<int> deleteCategoria(int id, int userId) async {
    final db = await instance.database;
    return await db.delete('categorias', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  //** */ --- TRANSACCIONES ---
  // Obtener todas las transacciones de un usuario
  Future<List<Transaccion>> getTransacciones(int userId) async {
    final db = await instance.database;
    final List<Map<String, Object?>> result;
    result = await db.query('transacciones', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((map) => Transaccion.fromMap(map)).toList();
  }

  // Insertar nueva transacción
  Future<int> insertTransaccion(Transaccion transaccion) async {
    final db = await instance.database;
    return await db.insert('transacciones', transaccion.toMap());
  }

  // Actualizar una transacción
  Future<int> updateTransaccion(Transaccion transaccion) async {
    final db = await instance.database;
    return await db.update(
      'transacciones',
      transaccion.toMap(),
      where: 'id = ?',
      whereArgs: [transaccion.id],
    );
  }

  // Obtener una transacción por id
  Future<Transaccion?> getTransaccionById(int id) async {
    final db = await instance.database;
    final result = await db.query('transacciones', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Transaccion.fromMap(result.first);
    }
    return null;
  }

  /// Borra una transacción y revierte el efecto en la cuenta correspondiente
  Future<bool> deleteTransaccion(int transaccionId, int userId) async {
    final transaccion = await getTransaccionById(transaccionId);
    if (transaccion == null) return false;

    final cuenta = await getCuentaById(transaccion.accountId);
    if (cuenta == null) return false;

    double nuevoMonto = cuenta.amount;
    // Si era gasto, al borrar hay que sumar el monto. Si era ingreso, restar.
    if ((transaccion.type ?? '').toLowerCase() == 'gasto') {
      nuevoMonto += transaccion.amount;
    } else {
      nuevoMonto -= transaccion.amount;
    }
    final cuentaActualizada = Cuenta(
      id: cuenta.id,
      userId: cuenta.userId,
      name: cuenta.name,
      type: cuenta.type,
      amount: nuevoMonto,
      moneda: cuenta.moneda
    );
    await updateCuenta(cuentaActualizada);
    await _deleteTransaccionDB(transaccionId); // CORRECTO
    return true;
  }

  // Método privado para solo borrar físicamente la transacción
  Future<int> _deleteTransaccionDB(int id) async {
    final db = await instance.database;
    return await db.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  }

  //** */ --- CUENTAS ---
  // Insertar nueva cuenta
  Future<int> insertCuenta(Cuenta cuenta) async {
    final db = await instance.database;
    return await db.insert('cuentas', cuenta.toMap());
  }

  // Obtener todas las cuentas de un usuario
  Future<List<Cuenta>> getCuentasByUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'cuentas',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((map) => Cuenta.fromMap(map)).toList();
  }

  // Obtener una cuenta por id
  Future<Cuenta?> getCuentaById(int id) async {
    final db = await instance.database;
    final result = await db.query('cuentas', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Cuenta.fromMap(result.first);
    }
    return null;
  }

  // Actualizar una cuenta
  Future<int> updateCuenta(Cuenta cuenta) async {
    final db = await instance.database;
    return await db.update(
      'cuentas',
      cuenta.toMap(),
      where: 'id = ?',
      whereArgs: [cuenta.id],
    );
  }

  // Eliminar una cuenta
  Future<int> deleteCuenta(int id) async {
    final db = await instance.database;
    return await db.delete('cuentas', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener el saldo total de todas las cuentas de un usuario
  Future<double> getSaldoTotal(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM cuentas WHERE user_id = ?',
      [userId],
    );
    return result.first['total'] != null ? (result.first['total'] as num).toDouble(): 0.0;
    }

  //** */ --- currency ---
  // Insertar configuración de moneda
  Future<int> insertCurrencyConfig(CurrencyConfig config) async {
    final db = await instance.database;
    return await db.insert('currency_config', config.toMap());
  }

  // Obtener configuración de moneda por usuario
  Future<Map<String, dynamic>?> getCurrencyConfigByUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'currency_config',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Actualizar configuración de moneda
  Future<int> updateCurrencyConfig(int id, Map<String, dynamic> config) async {
    final db = await instance.database;
    return await db.update(
      'currency_config',
      config,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar configuración de moneda
  Future<int> deleteCurrencyConfig(int id) async {
    final db = await instance.database;
    return await db.delete('currency_config', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener todas las configuraciones de moneda (opcional)
  Future<List<Map<String, dynamic>>> getAllCurrencyConfigs() async {
    final db = await instance.database;
    return await db.query('currency_config');
  }
  
  // Obtiene la versión de la base de datos
  Future<int> getDatabaseVersion() async {
  final db = await instance.database;
  // PRAGMA user_version retorna un mapa con la clave 'user_version'
  final result = await db.rawQuery('PRAGMA user_version;');
  return result.first.values.first as int;
}



}


  



