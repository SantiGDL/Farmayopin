import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dtos/resultado_registro.dart';
import '../dtos/resultado_iniciar_sesion.dart';

// Equivale al ServicioGeneral del backend: aquí viven las operaciones generales.
// No conoce pantallas, BuildContext ni navegación. LLama Endpoints

/*<--Lo utilizo para-->:

 ->Validar rol de usuarios
 ->Registrar clientes
*/


class ServicioGeneral {
  ServicioGeneral({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  static const _urlBase = 'http://localhost:5206/api/controladorGeneral';



  //<--Consultar ROL-->
  Future<ResultadoIniciarSesion> iniciarSesion(String correo, String password) async 
  {
    //Envio una peticion Post y Guardo el resultado en una variable
    try{
      final http.Response respuestaBackend = await _cliente.post(
          Uri.parse('$_urlBase/consultarRolUsuario'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({                                         
          'Correo': correo.trim(),
          'Pass': password,
        }),);
      //Interpreto el resultado que me llega de la petición
      if (respuestaBackend.statusCode == 200) 
      {
        final Map<String, dynamic> respuesta = jsonDecode(respuestaBackend.body);
        return ResultadoIniciarSesion(exito: true, mensaje: 'Credenciales correctas.',rol: respuesta['rol'],);
      }
      if (respuestaBackend.statusCode == 401) {
        return ResultadoIniciarSesion(exito: false,mensaje: 'Correo o contraseña incorrectos.');
      }
      else
      {
        return ResultadoIniciarSesion(exito: false,mensaje: 'No se pudo iniciar sesión.',);
      }
    }catch(error) {return ResultadoIniciarSesion(exito: false,mensaje: 'Error inesperado al inicio de sesión.',);}
  }

 

  void dispose() {
    _cliente.close();
  }
  
  //Registrar Cliente
  Future<ResultadoRegistro> registrarCliente(String nombre, String correo, String password,) async 
  {
    try {
      final respuesta = await _cliente.post(
        Uri.parse('$_urlBase/nuevoCliente'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'Nombre': nombre.trim(),
          'Correo': correo.trim(),
          'Pass': password,
          'Imagen': '',
        }),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return const ResultadoRegistro(
          true,
          'Usuario registrado correctamente.',
        );
      }
      return ResultadoRegistro(
        false,
        _leerError(respuesta.body),
      );
    } catch (_) {
      return const ResultadoRegistro(
        false,
        'No se pudo conectar con el servidor. Revisá que el backend esté corriendo.',
      );
    }
  }

  String _leerError(String cuerpo) {
    const mensajePredeterminado = 'No se pudo registrar el usuario.';
    if (cuerpo.isEmpty) return mensajePredeterminado;
    try {
      final datos = jsonDecode(cuerpo);
      if (datos is Map<String, dynamic> && datos['mensaje'] is String) {
        return datos['mensaje'] as String;
      }
      return mensajePredeterminado;
    } catch (_) {
      return cuerpo;
    }
  }

  
}
