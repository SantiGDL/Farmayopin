import 'package:flutter/material.dart';

import '../servicios/servicio_general.dart';
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

  //Iniciar Sesion
  Future<void> iniciarSesion(BuildContext referenciaPantalla) async{
     
    // Obtenego estado del formulario.
    final FormState? formulario = formKey.currentState;

    // Si el formulario no existe, termino.
    if (formulario == null) return;
    
    // Reviso los campos y muestro los errores si los hay.
    final bool formularioValido = formulario.validate();
    
    //Si el formulario tiene errores termio tambien
    if (formularioValido == false) return;
    
    // Si llego acá, puedo consultar al backend.

    final String correo = correoController.text;
    final String password = passwordController.text;
    final ResultadoIniciarSesion resultado =
    await _servicio.iniciarSesion(correo, password);

    // Mientras espero, el usuario pudo haber cerrado la pantalla.
    if (referenciaPantalla.mounted == false) return;
  
    // Si el servicio informa un fallo, mostramos el mensaje y terminamos.
    if (resultado.exito == false) 
    {
      _mostrarMensaje( referenciaPantalla, resultado.mensaje, esError: true);
      return;
    }

    if (resultado.rol == 'Admin') {
      Navigator.of(referenciaPantalla).pushReplacement(   //Desde la pantalla actual reemplazo:
        MaterialPageRoute(                                //defino ruta de pantalla de reemplazo
          builder: (context) 
          {
            return const AdminHomeScreen();
          }
      ));

    }

    if (resultado.rol == 'Cliente') {
      Navigator.of(referenciaPantalla).pushReplacement(
        MaterialPageRoute(builder: (context) {
          return const ClienteHomeScreen();
        }),
      );
      return;
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

  static void cerrarSesion(BuildContext context) {
    // Solo navegación por ahora: todavía no hay una sesión/token que borrar.
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
