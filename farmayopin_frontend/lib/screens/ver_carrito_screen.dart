import '../widgets/encabezado_cliente.dart';
import '../widgets/presentacion_cliente.dart';
import '../widgets/buscador_productos.dart';
import '../widgets/filtros_productos.dart';
import '../widgets/tarjeta_producto_cliente.dart';
import '../widgets/volver_cliente.dart';
import '../widgets/resumen_carrito_cliente.dart';
import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';
import '../dtos/carrito_cliente.dart';
import '../dtos/producto_listado.dart';
import '../servicios/servicio_cliente.dart';

class VerCarritoScreen extends StatefulWidget {
  const VerCarritoScreen({
    super.key,
    this.controlador = const ControladorCliente(),
  });

  final ControladorCliente controlador;

  @override
  State<VerCarritoScreen> createState() {
    return _VerCarritoScreenState();
  }
}

class _VerCarritoScreenState extends State<VerCarritoScreen> {
  CarritoCliente? carrito;
  bool cargando = true;
  bool guardando = false;
  bool sesionVencida = false;
  String? errorCarga;
  String busqueda = '';
  String categoria = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    if (guardando) return;
    setState(() {
      cargando = true;
      errorCarga = null;
      sesionVencida = false;
    });
    try {
      final CarritoCliente recibido = await widget.controlador.cargarCarrito();
      if (!mounted) {
        return;
      }
      setState(() {
        carrito = recibido;
        cargando = false;
      });
    } on SesionClienteVencida {
      if (!mounted) {
        return;
      }
      setState(() {
        carrito = null;
        cargando = false;
        sesionVencida = true;
        errorCarga = 'Volvé a iniciar sesión para consultar tu carrito.';
      });
    } on ErrorOperacionCliente catch (error) {
      if (!mounted) return;
      setState(() { errorCarga = error.mensaje; });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        cargando = false;
        errorCarga = 'No se pudo cargar tu carrito. Revisá la conexión e intentá nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ProductoListado> productos = [];
    final CarritoCliente? carritoActual = carrito;
    if (carritoActual != null) {
      for (final LineaCarritoCliente linea in carritoActual.lineas) {
        productos.add(linea.producto);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarCarrito,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncabezadoCliente(
                      cerrarSesion: () {
                        widget.controlador.cerrarSesion(context);
                      },
                    ),
                    VolverCliente(
                      volver: guardando
                          ? null
                          : () => widget.controlador.volver(context),
                    ),
                    const PresentacionCliente(
                      titulo: 'Mi Carrito',
                      descripcion: 'Revisá los productos que agregaste a tu carrito y editá las cantidades o eliminalos si lo necesitás.',
                    ),
                    const SizedBox(height: 22),
                    BuscadorProductos(
                      alCambiar: (String texto) {
                        setState(() {
                          busqueda = texto;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    FiltrosProductos(
                      productos: productos,
                      categoria: categoria,
                      alSeleccionar: (String seleccionada) {
                        setState(() {
                          categoria = seleccionada;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (guardando) const LinearProgressIndicator(),
                    _contenido(),
                    const SizedBox(height: 18),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: guardando
                            ? null
                            : () {
                                widget.controlador.seguirComprando(context);
                              },
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        label: const Text('Seguir comprando'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(205, 34),
                          foregroundColor: const Color(0xFF199F98),
                          side: const BorderSide(color: Color(0xFF199F98)),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorCarga != null) {
      return Column(
        children: [
          Text(errorCarga!, textAlign: TextAlign.center),
          if (sesionVencida)
            TextButton(
              onPressed: () {
                widget.controlador.cerrarSesion(context);
              },
              child: const Text('Iniciar sesión'),
            )
          else
            TextButton(
              onPressed: _cargarCarrito,
              child: const Text('Reintentar'),
            ),
        ],
      );
    }

    final CarritoCliente carritoActual = carrito!;
    if (carritoActual.lineas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 42,
              color: Color(0xFF50BDB5),
            ),
            SizedBox(height: 12),
            Text('Tu carrito está vacío.', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final List<LineaCarritoCliente> visibles = widget.controlador
        .filtrarCarrito(carritoActual, busqueda, categoria);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (carritoActual.desdeCopiaLocal)
          const Padding(padding: EdgeInsets.all(8), child: Text('Carrito guardado en este dispositivo. Reconectate para modificarlo o comprar.')),
        if (visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No se encontraron productos.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final LineaCarritoCliente linea in visibles)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TarjetaProductoCliente(
              producto: linea.producto,
              esCarrito: true,
              acciones: _cantidad(linea),
            ),
          ),
        // Buscar o filtrar no cambia los importes de todo el carrito.
        ResumenCarritoCliente(carrito: carritoActual),
        const SizedBox(height: 14),
        Center(
          child: FilledButton.icon(
            onPressed: guardando || carritoActual.desdeCopiaLocal
                ? null
                : () async {
                    await widget.controlador.pagarCarrito(
                      context,
                      carritoActual,
                    );
                    if (mounted) await _cargarCarrito();
                  },
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('Pagar carrito'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(205, 34),
              backgroundColor: const Color(0xFF199F98),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cantidad(LineaCarritoCliente linea) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBBBBBB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _botonCantidad(
                Icons.remove,
                'Disminuir cantidad',
                linea.cantidad <= 1
                    ? null
                    : () => _cambiarCantidad(linea, linea.cantidad - 1),
              ),
              Semantics(
                label:
                    'Cantidad de ${linea.producto.nombre}: ${linea.cantidad}',
                child: Text(
                  '${linea.cantidad}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              _botonCantidad(
                Icons.add,
                'Aumentar cantidad',
                linea.cantidad >= linea.producto.stock
                    ? null
                    : () => _cambiarCantidad(linea, linea.cantidad + 1),
              ),
            ],
          ),
        ),
        _botonCantidad(
          Icons.delete_outline,
          'Eliminar producto',
          () => _eliminar(linea),
        ),
      ],
    );
  }

  Widget _botonCantidad(
    IconData icono,
    String descripcion,
    VoidCallback? accion,
  ) {
    Color color = const Color(0xFF199F98);
    if (icono == Icons.delete_outline) {
      color = Colors.redAccent;
    }
    return IconButton(
      onPressed: guardando || carrito?.desdeCopiaLocal == true ? null : accion,
      tooltip: descripcion,
      icon: Icon(icono, size: 18, color: color),
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _cambiarCantidad(LineaCarritoCliente linea, int cantidad) async {
    await _guardarCambio(
      () => widget.controlador.cambiarCantidad(linea.id, cantidad),
    );
  }

  Future<void> _eliminar(LineaCarritoCliente linea) async {
    await _guardarCambio(() => widget.controlador.eliminarLinea(linea.id));
  }

  Future<void> _guardarCambio(
    Future<CarritoCliente> Function() operacion,
  ) async {
    if (guardando) return;
    setState(() {
      guardando = true;
    });
    try {
      final CarritoCliente recibido = await operacion();
      if (mounted) {
        setState(() {
          carrito = recibido;
        });
      }
    } catch (error) {
      if (mounted) widget.controlador.mostrarError(context, error);
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }
}
