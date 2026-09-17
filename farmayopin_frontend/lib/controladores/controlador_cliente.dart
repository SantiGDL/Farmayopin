import 'package:flutter/material.dart';

import '../servicios/servicio_cliente.dart';
import '../dtos/carrito_cliente.dart';
import '../dtos/producto_listado.dart';
import '../screens/listar_productos_screen.dart';
import '../screens/ver_carrito_screen.dart';
import '../screens/detalle_producto_screen.dart';
import 'controlador_general.dart';

// Coordina los botones del cliente. Las operaciones se delegan al servicio.
class ControladorCliente {
  const ControladorCliente({this.servicio = const ServicioCliente()});

  final ServicioCliente servicio;

  void verProductos(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return ListarProductosScreen(
            esCliente: true,
            controladorCliente: this,
          );
        },
      ),
    );
  }

  void verCarrito(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return VerCarritoScreen(controlador: this);
        },
      ),
    );
  }

  Future<List<ProductoListado>> listarProductos() {
    return servicio.listarProductos();
  }

  Future<CarritoCliente> cargarCarrito() {
    return servicio.verCarrito();
  }

  void verProducto(BuildContext referenciaPantalla, ProductoListado producto) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return DetalleProductoScreen(producto: producto, esCliente: true);
        },
      ),
    );
  }

  void seguirComprando(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return ListarProductosScreen(
            esCliente: true,
            controladorCliente: this,
          );
        },
      ),
    );
  }

  List<ProductoListado> filtrarProductos(
    List<ProductoListado> productos,
    String busqueda,
    String categoria,
  ) {
    final String texto = busqueda.trim().toLowerCase();
    final List<ProductoListado> visibles = [];
    for (final ProductoListado producto in productos) {
      final bool coincideTexto =
          producto.nombre.toLowerCase().contains(texto) ||
          producto.descripcion.toLowerCase().contains(texto);
      final bool coincideCategoria =
          categoria == 'Todos' || producto.categoria == categoria;
      if (coincideTexto && coincideCategoria) {
        visibles.add(producto);
      }
    }
    return visibles;
  }

  List<LineaCarritoCliente> filtrarCarrito(
    CarritoCliente carrito,
    String busqueda,
    String categoria,
  ) {
    final List<ProductoListado> productos = [];
    for (final LineaCarritoCliente linea in carrito.lineas) {
      productos.add(linea.producto);
    }
    final List<ProductoListado> visibles = filtrarProductos(
      productos,
      busqueda,
      categoria,
    );
    final List<LineaCarritoCliente> lineas = [];
    for (final LineaCarritoCliente linea in carrito.lineas) {
      if (visibles.contains(linea.producto)) {
        lineas.add(linea);
      }
    }
    return lineas;
  }

  void mostrarPendiente(BuildContext referenciaPantalla, String funcion) {
    _mostrarAviso(referenciaPantalla, '$funcion todavía no está disponible.');
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
