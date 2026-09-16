import 'package:flutter/material.dart';

import '../servicios/servicio_admin.dart';
import '../screens/crear_producto_screen.dart';
import 'controlador_general.dart';

// Recibe los clics del panel y del formulario de producto.
// Las operaciones se delegan al servicio; la navegación pertenece al controlador.
class ControladorAdmin {
  const ControladorAdmin({this.servicio = const ServicioAdmin()});

  final ServicioAdmin servicio;

  void abrirCrearProducto(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CrearProductoScreen()));
  }

  void mostrarPendiente(BuildContext context, String funcion) {
    _mostrarAviso(
      context,
      servicio.funcionPendiente(funcion),
      reemplazar: true,
    );
  }

  void cerrarSesion(BuildContext context) {
    ControladorGeneral.cerrarSesion(context);
  }

  void guardarProducto(BuildContext context) {
    _mostrarAviso(context, servicio.guardarProducto());
  }

  void cancelarProducto(BuildContext context) {
    _mostrarAviso(context, servicio.cancelarProducto());
  }

  void seleccionarFoto(BuildContext context) {
    _mostrarAviso(context, servicio.seleccionarFoto());
  }

  void cerrarSesionDesdeProducto(BuildContext context) {
    _mostrarAviso(context, servicio.cerrarSesionDesdeProducto());
  }

  void _mostrarAviso(
    BuildContext context,
    String mensaje, {
    bool reemplazar = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (reemplazar) messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
