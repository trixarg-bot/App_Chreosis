import 'package:sqflite/sqflite.dart';
import 'package:chreosis_app/utils/app_loger.dart';

class MigrationHelper {
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    logger.w('🚧 Iniciando migración de BD: v$oldVersion ➡️ v$newVersion');

    if (oldVersion < 2) {
      await db.execute("DELETE FROM categorias WHERE ID = 2");

      await db.execute('''
        CREATE TABLE cuentas_nueva (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT,
          amount REAL DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES usuarios(id),
          UNIQUE(user_id, name)
        );
      ''');

      await db.execute('''
        INSERT INTO categorias_nueva (id, user_id, name, type)
        SELECT id, user_id, name, type FROM categorias;
      ''');

      await db.execute('DROP TABLE categorias');
      await db.execute('ALTER TABLE categorias_nueva RENAME TO categorias');

      logger.i('🚧 Tabla "categorias" actualizada con UNIQUE en "name"');
    }

    if (oldVersion < 3) {
      logger.i('🔁 Migración v3: aplicar UNIQUE(user_id, name) en cuentas');
      await db.execute('DELETE FROM cuentas WHERE ID in (2,3,4,5,6,7,8)');
      await db.execute('''
        CREATE TABLE cuentas_nueva (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT,
          amount REAL DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES usuarios(id),
          UNIQUE(user_id, name)
        );
      ''');

      await db.execute('''
        INSERT INTO cuentas_nueva (id, user_id, name, type, amount)
        SELECT id, user_id, name, type, amount FROM cuentas;
      ''');

      await db.execute('DROP TABLE cuentas');
      await db.execute('ALTER TABLE cuentas_nueva RENAME TO cuentas');

      logger.i('✅ Tabla "cuentas" actualizada con UNIQUE(user_id, name)');
    }

    if (oldVersion < 4) {
      logger.i(
        '🔁 Migración v4: quitan la restriccion NOT NULL de Email en usuarios',
      );
      await db.execute('DROP TABLE usuarios');
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
      logger.i('✅ Tabla "usuarios" actualizada con UNIQUE(email)');
    }

    if (oldVersion < 5) {
      logger.i('🔁 Migración v5: agregar icon_code a categorias');
      await db.execute('''
        ALTER TABLE categorias ADD COLUMN icon_code INTEGER;
      ''');
      logger.i('✅ Tabla "categorias" actualizada con icon_code');
    }

    if (oldVersion < 6) {
      logger.i('🔁 Migración v6: agregar lugar a transacciones');
      await db.execute('ALTER TABLE transacciones ADD COLUMN place TEXT');
      logger.i('✅ Tabla "transacciones" actualizada con lugar');
    }

    if (oldVersion < 7) {
      logger.i(
        '🔁 Migración v7: Agregando campos de moneda y la tabla de configuración',
      );

      // 1. Añadir columna 'moneda' a la tabla 'cuentas'
      // Se añade con un valor por defecto para las filas existentes.
      await db.execute(
        "ALTER TABLE cuentas ADD COLUMN moneda TEXT NOT NULL DEFAULT 'DOP'",
      );
      logger.i('✅ Columna "moneda" agregada a la tabla "cuentas"');

      // 2. Añadir columnas a la tabla 'transacciones'
      await db.execute(
        "ALTER TABLE transacciones ADD COLUMN moneda TEXT NOT NULL DEFAULT 'DOP'",
      );
      await db.execute(
        "ALTER TABLE transacciones ADD COLUMN conversion INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE transacciones ADD COLUMN monto_convertido REAL",
      );
      logger.i(
        '✅ Columnas de moneda y conversión agregadas a la tabla "transacciones"',
      );

      // 3. Crear la tabla 'currency_config'
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
      logger.i('✅ Tabla "currency_config" creada exitosamente');
    }

    if (oldVersion < 8) {
      logger.i('🔁 Migración v8: agregar tasa_conversion a transacciones');
      await db.execute(
        'ALTER TABLE transacciones ADD COLUMN tasa_conversion REAL',
      );
      logger.i(
        '✅ Columna "tasa_conversion" agregada a la tabla "transacciones"',
      );
    }
  }
}
