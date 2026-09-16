import 'package:flutter/material.dart';

import '../servicios/servicio_cliente.dart';
import 'controlador_general.dart';

// Coordina los botones del cliente. Las operaciones se delegan al servicio.
class ControladorCliente {
  const ControladorCliente({this.servicio = const ServicioCliente()});

  final ServicioCliente servicio;

  void verProductos(BuildContext referenciaPantalla) {
    _mostrarAviso(referenciaPantalla, servicio.verProductos());
  }

  void verCarrito(BuildContext referenciaPantalla) {
    _mostrarAviso(referenciaPantalla, servicio.verCarrito());
  }

  void verHistorico(BuildContext referenciaPantalla) {
    _mostrarAviso(referenciaPantalla, servicio.verHistorico());
  }

  void cerrarSesion(BuildContext referenciaPantalla) {
    ControladorGeneral.cerrarSesion(referenciaPantalla);
  }

  void _mostrarAviso(BuildContext referenciaPantalla, String mensaje) {
    final ScaffoldMessengerState mensajero = ScaffoldMessenger.of(
      referenciaPantalla,
    );
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
