import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';
import '../dtos/detalle_compra.dart';
import '../dtos/producto_listado.dart';
import '../servicios/servicio_cliente.dart';
import '../widgets/compras_cliente_widgets.dart';
import '../widgets/productos_cliente_widgets.dart';

class DetalleCompraScreen extends StatefulWidget {
  const DetalleCompraScreen({
    super.key,
    required this.compraId,
    this.controlador = const ControladorCliente(),
  });
  final int compraId;
  final ControladorCliente controlador;

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  DetalleCompra? compra;
  bool cargando = true;
  bool sesionVencida = false;
  String? errorCarga;
  String busqueda = '';
  String categoria = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      errorCarga = null;
      sesionVencida = false;
    });
    try {
      final DetalleCompra recibida = await widget.controlador
          .cargarDetalleCompra(widget.compraId);
      if (!mounted) return;
      setState(() {
        compra = recibida;
      });
    } on SesionClienteVencida {
      if (!mounted) return;
      setState(() {
        sesionVencida = true;
        errorCarga = 'Volvé a iniciar sesión para consultar esta compra.';
      });
    } on ErrorOperacionCliente catch (error) {
      if (!mounted) return;
      setState(() {
        errorCarga = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorCarga = 'No se pudo cargar la compra. Revisá la conexión e intentá nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoCliente(
                    cerrarSesion: () =>
                        widget.controlador.cerrarSesion(context),
                  ),
                  VolverCliente(
                    volver: () => widget.controlador.volver(context),
                  ),
                  const PresentacionCliente(
                    titulo: 'Detalle Compra',
                    descripcion: 'Revisá el detalle de la compra realizada en la fecha seleccionada.',
                  ),
                  const SizedBox(height: 22),
                  _contenido(),
                ],
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
      return ErrorConsultaCompra(
        mensaje: errorCarga!,
        sesionVencida: sesionVencida,
        reintentar: _cargar,
        iniciarSesion: () => widget.controlador.cerrarSesion(context),
      );
    }
    final DetalleCompra actual = compra!;
    final List<ProductoListado> productos = [];
    for (final LineaCompra linea in actual.lineas) {
      productos.add(linea.producto);
    }
    final List<LineaCompra> visibles = widget.controlador.filtrarDetalleCompra(
      actual,
      busqueda,
      categoria,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuscadorProductos(
          alCambiar: (String texto) => setState(() {
            busqueda = texto;
          }),
        ),
        const SizedBox(height: 12),
        FiltrosProductos(
          productos: productos,
          categoria: categoria,
          soloCategoriasDisponibles: true,
          alSeleccionar: (String seleccionada) => setState(() {
            categoria = seleccionada;
          }),
        ),
        const SizedBox(height: 14),
        FechaCompraCliente(fecha: actual.fechaCompra),
        const SizedBox(height: 6),
        Text(
          '${widget.controlador.identificadorPedido(actual.id)} · Pagada',
          style: const TextStyle(fontSize: 11, color: Color(0xFF168E88)),
        ),
        const SizedBox(height: 18),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              actual.lineas.isEmpty
                  ? 'Esta compra no tiene productos.'
                  : 'No se encontraron productos.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final LineaCompra linea in visibles) _producto(linea),
        _resumen(actual),
      ],
    );
  }

  Widget _producto(LineaCompra linea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImagenProducto(producto: linea.producto, tamano: 62),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linea.producto.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  linea.producto.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatearImporte(linea.producto.precio),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF239F98),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF7),
                        border: Border.all(color: const Color(0xFFBBBBBB)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Cantidad: ${linea.cantidad}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF168E88),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumen(DetalleCompra actual) {
    // Los filtros solo cambian las filas visibles; los totales son de la compra completa.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          _importe(
            'Subtotal (${actual.cantidadProductos} productos)',
            actual.subtotal,
            false,
          ),
          const SizedBox(height: 6),
          _importe('Envío', actual.envio, false),
          const Divider(),
          _importe('Total', actual.total, true),
        ],
      ),
    );
  }

  Widget _importe(String etiqueta, double valor, bool destacar) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: destacar ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatearImporte(valor),
          style: const TextStyle(fontSize: 11, color: Color(0xFF168E88)),
        ),
      ],
    );
  }
}
