import '../screens/editar_producto_screen.dart';
import '../dtos/compra_producto.dart';
import '../screens/historico_producto_screen.dart';
import '../utils/formatear_importe.dart';
import '../dtos/producto_listado.dart';
import '../screens/listar_productos_screen.dart';
import '../screens/detalle_producto_screen.dart';

import 'package:flutter/material.dart';

import '../servicios/servicio_admin.dart';
import '../screens/crear_producto_screen.dart';
import 'controlador_general.dart';

// Recibe los clics del panel y del formulario de producto.
// Las operaciones se delegan al servicio; la navegación pertenece al controlador.
class ControladorAdmin {
  const ControladorAdmin({this.servicio = const ServicioAdmin()});

  final ServicioAdmin servicio;

  void abrirHistoricoProducto(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HistoricoProductoScreen(controlador: this),
    ));
  }

  Future<ProductoListado?> seleccionarProductoHistorial(BuildContext context) {
    return Navigator.of(context).push<ProductoListado>(MaterialPageRoute(
      builder: (_) => ListarProductosScreen(
        seleccionarParaHistorial: true,
        controladorAdmin: this,
      ),
    ));
  }

  Future<ProductoListado?> seleccionarProductoEdicion(BuildContext context) {
    return Navigator.of(context).push<ProductoListado>(MaterialPageRoute(
      builder: (_) => ListarProductosScreen(
        seleccionarParaEdicion: true, controladorAdmin: this,
      ),
    ));
  }

  Future<ProductoListado?> abrirEditarProducto(BuildContext context) {
    return Navigator.of(context).push<ProductoListado>(MaterialPageRoute(
      builder: (_) => EditarProductoScreen(controladorAdmin: this),
    ));
  }

  void devolverProducto(BuildContext context, ProductoListado producto) {
    Navigator.of(context).pop(producto);
  }

  Future<List<CompraProducto>> cargarHistoricoProducto(int productoId) {
    return servicio.historicoProducto(productoId);
  }

  List<CompraProducto> filtrarHistoricoProducto(List<CompraProducto> compras, String busqueda) {
    final String texto = busqueda.trim().toLowerCase();
    return compras.where((CompraProducto compra) {
      final DateTime fecha = compra.fechaCompra;
      final String datos = '${compra.nombreCliente} ${compra.correoCliente} '
          '${compra.cantidadProducto} ${formatearImporte(compra.precioUnitario)} '
          '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.toIso8601String()}';
      return datos.toLowerCase().contains(texto);
    }).toList();
  }

  void abrirListadoProductos(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return ListarProductosScreen(controladorAdmin: this);
        },
      ),
    );
  }

  //// Obtiene la lista de productos para mostrarla en pantalla.
  Future<List<ProductoListado>> cargarProductosPantalla() {
    return servicio.listarProductos();
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

  Future<void> verProducto(BuildContext referenciaPantalla, ProductoListado producto) async {
    await Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) => DetalleProductoScreen(producto: producto, controladorAdmin: this),
      ),
    );
  }

  Future<ProductoListado?> editarProducto(
    BuildContext referenciaPantalla,
    ProductoListado producto,
  ) {
    return Navigator.of(referenciaPantalla).push<ProductoListado>(MaterialPageRoute(
      builder: (_) => EditarProductoScreen(producto: producto, controladorAdmin: this),
    ));
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
