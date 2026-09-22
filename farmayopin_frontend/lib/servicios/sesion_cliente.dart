import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// Conserva el nombre existente para reutilizar todos los consumidores del token.
// Una única clave evita restaurar una sesión escrita parcialmente.
class SesionCliente {
  static const String clave = 'farmayopin.sesion';
  static String? token;
  static int? usuarioId;
  static String? rol;

  static void limpiarMemoria() {
    token = null;
    usuarioId = null;
    rol = null;
  }

  static Future<void> guardar(
    int id,
    String rolUsuario,
    String? tokenUsuario,
  ) async {
    if (id <= 0 ||
        !['Admin', 'Cliente'].contains(rolUsuario) ||
        (rolUsuario == 'Cliente' &&
            (tokenUsuario == null || tokenUsuario.isEmpty))) {
      throw const FormatException('La sesión recibida está incompleta.');
    }
    final SharedPreferences preferencias =
        await SharedPreferences.getInstance();
    final String? tokenGuardado = rolUsuario == 'Cliente' ? tokenUsuario : null;
    final bool guardado = await preferencias.setString(
      clave,
      jsonEncode({'usuarioId': id, 'rol': rolUsuario, 'token': ?tokenGuardado}),
    );
    if (!guardado) throw StateError('No se pudo guardar la sesión.');
    usuarioId = id;
    rol = rolUsuario;
    token = tokenGuardado;
  }

  static Future<void> restaurar() async {
    limpiarMemoria();
    final SharedPreferences preferencias =
        await SharedPreferences.getInstance();
    final String? guardado = preferencias.getString(clave);
    if (guardado == null) return;
    try {
      final Map<String, dynamic> datos =
          jsonDecode(guardado) as Map<String, dynamic>;
      final int id = datos['usuarioId'] as int;
      final String rolGuardado = datos['rol'] as String;
      final String? tokenGuardado = datos['token'] as String?;
      if (id <= 0 ||
          !['Admin', 'Cliente'].contains(rolGuardado) ||
          (rolGuardado == 'Cliente' &&
              (tokenGuardado == null || tokenGuardado.isEmpty))) {
        throw const FormatException('Sesión inválida');
      }
      usuarioId = id;
      rol = rolGuardado;
      token = rolGuardado == 'Cliente' ? tokenGuardado : null;
    } catch (_) {
      await preferencias.remove(clave);
    }
  }

  static Future<void> cerrar() async {
    limpiarMemoria();
    final SharedPreferences preferencias =
        await SharedPreferences.getInstance();
    final bool eliminado = await preferencias.remove(clave);
    if (!eliminado) throw StateError('No se pudo borrar la sesión guardada.');
  }
}
