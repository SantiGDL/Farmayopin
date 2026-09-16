import '../servicios/servicio_cliente.dart';

// Misma agrupación que en el backend. Las futuras pantallas de cliente
// llamarán a este controlador y este delegará sus operaciones al servicio.
class ControladorCliente {
  const ControladorCliente({this.servicio = const ServicioCliente()});

  final ServicioCliente servicio;
}
