import 'package:flutter/material.dart';

import '../servicios/servicio_general.dart';
import '../servicios/sesion_cliente.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';
import '../dtos/resultado_iniciar_sesion.dart';
import '../screens/admin_home_screen.dart';
import '../screens/cliente_home_screen.dart';

// Pantalla -> ControladorGeneral -> ServicioGeneral.
// A diferencia de un controller HTTP de C#, este recibe eventos de la interfaz.
// Cada pantalla crea su propia instancia para no compartir campos ni contraseñas.
class ControladorGeneral extends ChangeNotifier {
  ControladorGeneral({ServicioGeneral? servicio})
    : _servicio = servicio ?? ServicioGeneral();

  final ServicioGeneral _servicio;
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmacionController = TextEditingController();
  bool ocultarPassword = true;
  bool ocultarConfirmacion = true;
  bool enviando = false;
  bool _cerrado = false;

  void alternarPassword() {
    ocultarPassword = !ocultarPassword;
    notifyListeners(); // Le pide a la vista que vuelva a dibujarse.
  }

  void alternarConfirmacion() {
    ocultarConfirmacion = !ocultarConfirmacion;
    notifyListeners();
  }

  Future<void> iniciarSesion(BuildContext referenciaPantalla) async {
    if (enviando) return;
    final FormState? formulario = formKey.currentState;
    if (formulario == null || !formulario.validate()) return;
    enviando = true;
    notifyListeners();
    try {
      final String correo = correoController.text;
      final String password = passwordController.text;
      final ResultadoIniciarSesion resultado = await _servicio.iniciarSesion(correo, password);
      if (_cerrado || !referenciaPantalla.mounted) return;
      if (!resultado.exito) {
        _mostrarMensaje(referenciaPantalla, resultado.mensaje, esError: true);
        return;
      }
      try {
        await SesionCliente.guardar(resultado.usuarioId ?? 0, resultado.rol ?? '', resultado.token);
      } catch (_) {
        if (referenciaPantalla.mounted) {
          _mostrarMensaje(referenciaPantalla, 'No se pudo guardar la sesión. Intentá nuevamente.', esError: true);
        }
        return;
      }
      if (_cerrado || !referenciaPantalla.mounted) return;
      passwordController.clear();
      final Widget pantalla = resultado.rol == 'Admin'
          ? const AdminHomeScreen() : const ClienteHomeScreen();
      Navigator.of(referenciaPantalla).pushReplacement(MaterialPageRoute(builder: (_) => pantalla));
    } finally {
      if (!_cerrado) {
        enviando = false;
        notifyListeners();
      }
    }
  }

  //Registrar Cliente
  Future<void> registrarCliente(BuildContext context) async {
    if (enviando || !formKey.currentState!.validate()) return;
    enviando = true;
    notifyListeners();
    try {
      final resultado = await _servicio.registrarCliente(
        nombreController.text,
        correoController.text,
        passwordController.text,);
      // La petición puede terminar cuando el usuario ya salió de la pantalla.
      if (_cerrado || !context.mounted) return;
      _mostrarMensaje(context, resultado.mensaje, esError: !resultado.exito);
      if (resultado.exito) volver(context);
    } finally {
      if (!_cerrado) {
        enviando = false;
        notifyListeners();
      }
    }
  }

  void abrirRegistro(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void volver(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<void> cerrarSesion(BuildContext context) async {
    try {
      await SesionCliente.cerrar();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo borrar la sesión guardada. Intentá cerrar sesión nuevamente.'),
        ));
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _mostrarMensaje(
    BuildContext context,
    String mensaje, {
    bool esError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : null,
      ),
    );
  }

  // Los validadores devuelven null si el dato es válido, o un mensaje de error.
  String? validarNombre(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Ingresá tu nombre completo.';
    if (name.length < 2) return 'El nombre es demasiado corto.';
    return null;
  }

  String? validarCorreo(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresá tu correo electrónico.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingresá un correo válido.';
    }
    return null;
  }

  String? validarPasswordRegistro(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Ingresá una contraseña.';
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  String? validarConfirmacion(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Confirmá tu contraseña.';
    if (confirm != passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  String? validarPasswordLogin(String? value) {
    return value == null || value.isEmpty ? 'Ingresá tu contraseña.' : null;
  }

  @override
  void dispose() {
    _cerrado = true;
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmacionController.dispose();
    _servicio.dispose();
    super.dispose();
  }
}
