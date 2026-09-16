import '../dtos/producto_listado.dart';
import '../screens/listar_productos_screen.dart';

import 'package:flutter/material.dart';

import '../servicios/servicio_admin.dart';
import '../screens/crear_producto_screen.dart';
import 'controlador_general.dart';

// Recibe los clics del panel y del formulario de producto.
// Las operaciones se delegan al servicio; la navegación pertenece al controlador.
class ControladorAdmin {
  const ControladorAdmin({this.servicio = const ServicioAdmin()});

  final ServicioAdmin servicio;

  void abrirListadoProductos(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return const ListarProductosScreen();
        },
      ),
    );
  }

  List<ProductoListado> cargarProductosEjemplo() {
    return servicio.listarProductosEjemplo();
  }

  List<ProductoListado> filtrarProductos(
    List<ProductoListado> productos,
    String busqueda,
    String categoria,
  ) {
    final List<ProductoListado> resultado = [];
    final String texto = busqueda.trim().toLowerCase();
    for (final ProductoListado producto in productos) {
      final bool coincideCategoria =
          categoria == 'Todos' || producto.categoria == categoria;
      final bool coincideTexto =
          producto.nombre.toLowerCase().contains(texto) ||
          producto.descripcion.toLowerCase().contains(texto);
      if (coincideCategoria && coincideTexto) {
        resultado.add(producto);
      }
    }
    return resultado;
  }

  void verProducto(BuildContext referenciaPantalla, ProductoListado producto) {
    mostrarPendiente(referenciaPantalla, 'Ver ${producto.nombre}');
  }

  void editarProducto(
    BuildContext referenciaPantalla,
    ProductoListado producto,
  ) {
    mostrarPendiente(referenciaPantalla, 'Editar ${producto.nombre}');
  }

  void abrirCrearProducto(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CrearProductoScreen()));
  }

  void volverAlMenu(BuildContext referenciaPantalla) {
    // Crear producto se abrió con push: pop recupera el menú anterior.
    Navigator.of(referenciaPantalla).pop();
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
