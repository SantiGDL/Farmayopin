import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

// Solo copias de datos del cliente. Nunca guarda sesión, token o contraseña.
// Se conserva el JSON del contrato existente para no crear otro modelo de datos.
class PersistenciaCliente {
  PersistenciaCliente({this.fabrica, this.ruta});
  static final PersistenciaCliente instancia = PersistenciaCliente();
  final DatabaseFactory? fabrica;
  final String? ruta;
  Future<Database>? _apertura;

  bool get disponible =>
      fabrica != null ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS));

  Future<Database> _abrir() async {
    final DatabaseFactory motor = fabrica ?? databaseFactory;
    final String archivo =
        ruta ??
        path.join(await motor.getDatabasesPath(), 'farmayopin_cliente.db');
    return motor.openDatabase(
      archivo,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''CREATE TABLE copias_cliente (
          usuario_id INTEGER NOT NULL,
          tipo TEXT NOT NULL,
          clave INTEGER NOT NULL,
          contenido TEXT NOT NULL,
          actualizado TEXT NOT NULL,
          PRIMARY KEY (usuario_id, tipo, clave)
        )''');
        },
      ),
    );
  }

  Future<Database> _base() async {
    _apertura ??= _abrir();
    try {
      return await _apertura!;
    } catch (_) {
      _apertura = null;
      rethrow;
    }
  }

  Future<void> guardar(
    int usuarioId,
    String tipo,
    int clave,
    String contenido,
  ) async {
    if (!disponible) return;
    final Database db = await _base();
    await db.insert('copias_cliente', {
      'usuario_id': usuarioId,
      'tipo': tipo,
      'clave': clave,
      'contenido': contenido,
      'actualizado': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> leer(int usuarioId, String tipo, int clave) async {
    if (!disponible) return null;
    final Database db = await _base();
    final List<Map<String, Object?>> filas = await db.query(
      'copias_cliente',
      columns: ['contenido'],
      where: 'usuario_id = ? AND tipo = ? AND clave = ?',
      whereArgs: [usuarioId, tipo, clave],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return filas.single['contenido'] as String;
  }

  Future<void> cerrar() async {
    if (_apertura != null) {
      final Database db = await _apertura!;
      await db.close();
      _apertura = null;
    }
  }
}
