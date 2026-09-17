import 'package:flutter/material.dart';

import '../servicios/servicio_cliente.dart';
import '../dtos/carrito_cliente.dart';
import '../dtos/compra_confirmada.dart';
import '../dtos/producto_listado.dart';
import '../screens/listar_productos_screen.dart';
import '../screens/ver_carrito_screen.dart';
import '../screens/detalle_producto_screen.dart';
import '../screens/confirmar_compra_screen.dart';
import 'controlador_general.dart';

// Coordina los botones del cliente. Las operaciones se delegan al servicio.
class ControladorCliente {
  const ControladorCliente({this.servicio = const ServicioCliente()});

  final ServicioCliente servicio;

  void verProductos(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'cliente/productos'),
        builder: (context) {
          return ListarProductosScreen(
            esCliente: true,
            controladorCliente: this,
          );
        },
      ),
    );
  }

  Future<void> verCarrito(BuildContext referenciaPantalla) async {
    await Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'cliente/carrito'),
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

  Future<void> verProducto(
    BuildContext referenciaPantalla,
    ProductoListado producto,
  ) async {
    await Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) {
          return DetalleProductoScreen(
            producto: producto,
            esCliente: true,
            controladorCliente: this,
          );
        },
      ),
    );
  }

  void seguirComprando(BuildContext referenciaPantalla) {
    final NavigatorState navegador = Navigator.of(referenciaPantalla);
    bool encontroCatalogo = false;
    navegador.popUntil((Route<dynamic> ruta) {
      encontroCatalogo = ruta.settings.name == 'cliente/productos';
      return encontroCatalogo || ruta.isFirst;
    });
    if (!encontroCatalogo) {
      verProductos(navegador.context);
    }
  }

  void volver(BuildContext referenciaPantalla) {
    Navigator.of(referenciaPantalla).maybePop();
  }

  Future<void> pagarCarrito(
    BuildContext referenciaPantalla,
    CarritoCliente carrito,
  ) async {
    if (carrito.lineas.isEmpty) return;
    await Navigator.of(referenciaPantalla).push(
      MaterialPageRoute(
        builder: (context) => ConfirmarCompraScreen(controlador: this),
      ),
    );
  }

  Future<void> agregarProducto(
    BuildContext referenciaPantalla,
    ProductoListado producto,
    int cantidad,
  ) async {
    try {
      await servicio.agregarProducto(producto.id, cantidad);
      if (!referenciaPantalla.mounted) return;
      _mostrarAviso(
        referenciaPantalla,
        'Agregaste $cantidad unidad(es) de ${producto.nombre} al carrito.',
      );
    } catch (error) {
      if (!referenciaPantalla.mounted) return;
      mostrarError(referenciaPantalla, error);
    }
  }

  Future<CarritoCliente> cambiarCantidad(int lineaId, int cantidad) {
    return servicio.cambiarCantidad(lineaId, cantidad);
  }

  Future<CarritoCliente> eliminarLinea(int lineaId) {
    return servicio.eliminarLinea(lineaId);
  }

  Future<bool> confirmarCompra(
    BuildContext referenciaPantalla,
    String? metodo,
  ) async {
    if (metodo == null) {
      _mostrarAviso(referenciaPantalla, 'Seleccioná un método de pago.');
      return false;
    }
    try {
      final CompraConfirmada compra = await servicio.confirmarCompra();
      if (!referenciaPantalla.mounted) return true;
      _mostrarAviso(
        referenciaPantalla,
        'Compra #${compra.compraId} confirmada correctamente.',
      );
      Navigator.of(referenciaPantalla).pop();
      return true;
    } catch (error) {
      if (referenciaPantalla.mounted) mostrarError(referenciaPantalla, error);
      return false;
    }
  }

  void mostrarError(BuildContext referenciaPantalla, Object error) {
    if (error is SesionClienteVencida) {
      ScaffoldMessenger.of(referenciaPantalla).showSnackBar(
        SnackBar(
          content: const Text('Tu sesión venció. Volvé a iniciar sesión.'),
          action: SnackBarAction(
            label: 'Iniciar sesión',
            onPressed: () => cerrarSesion(referenciaPantalla),
          ),
        ),
      );
      return;
    }
    String mensaje =
        'No se pudo completar la operación. Revisá la conexión y actualizá el carrito antes de volver a intentarlo.';
    if (error is ErrorOperacionCliente) mensaje = error.mensaje;
    _mostrarAviso(referenciaPantalla, mensaje);
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
