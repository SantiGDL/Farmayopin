import 'package:flutter/material.dart';

import '../controladores/controlador_admin.dart';
import '../dtos/compra_producto.dart';
import '../dtos/producto_listado.dart';
import '../utils/formatear_importe.dart';
import '../widgets/buscador_productos.dart';
import '../widgets/encabezado_admin.dart';
import '../widgets/error_consulta_compra.dart';
import '../widgets/fecha_compra_cliente.dart';
import '../widgets/imagen_producto.dart';
import '../widgets/paginacion_compras.dart';
import '../widgets/volver_cliente.dart';

// ================== ESTRUCTURA Y LÓGICA ==================

class HistoricoProductoScreen extends StatefulWidget {
  const HistoricoProductoScreen({
    super.key,
    this.controlador = const ControladorAdmin(),
  });
  final ControladorAdmin controlador;

  @override
  State<HistoricoProductoScreen> createState() =>
      _HistoricoProductoScreenState();
}

class _HistoricoProductoScreenState extends State<HistoricoProductoScreen> {
  ProductoListado? producto;
  List<CompraProducto> compras = [];
  bool cargando = false;
  String? errorCarga;
  String busqueda = '';
  int pagina = 1;
  int consultaActual = 0;
  static const int comprasPorPagina = 7;
  static const Color turquesa = Color(0xFF50BDB5);

  Future<void> _seleccionar() async {
    final ProductoListado? seleccionado = await widget.controlador
        .seleccionarProductoHistorial(context);
    if (!mounted || seleccionado == null) return;
    setState(() {
      producto = seleccionado;
      busqueda = '';
      pagina = 1;
    });
    await _cargar();
  }

  Future<void> _cargar() async {
    final ProductoListado? seleccionado = producto;
    if (seleccionado == null) return;
    // Si cambia el producto durante una consulta, su respuesta anterior se descarta.
    final int consulta = ++consultaActual;
    setState(() {
      cargando = true;
      errorCarga = null;
      compras = [];
      pagina = 1;
    });
    try {
      final List<CompraProducto> recibidas = await widget.controlador
          .cargarHistoricoProducto(seleccionado.id);
      if (!mounted || consulta != consultaActual) return;
      setState(() {
        compras = recibidas;
      });
    } catch (_) {
      if (!mounted || consulta != consultaActual) return;
      setState(() {
        errorCarga = 'No se pudieron cargar las compras. Revisá la conexión e intentá nuevamente.';
      });
    } finally {
      if (mounted && consulta == consultaActual) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CompraProducto> filtradas = widget.controlador
        .filtrarHistoricoProducto(compras, busqueda);
    final int paginas = filtradas.isEmpty
        ? 1
        : (filtradas.length / comprasPorPagina).ceil();
    return Scaffold(
      body: SafeArea(
        child: _crearContenidoCentrado(context, filtradas, paginas),
      ),
    );
  }

  Widget _crearEstructuraPantalla(
    BuildContext context,
    List<CompraProducto> filtradas,
    int paginas,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoAdmin(
          cerrarSesion: () =>
              widget.controlador.cerrarSesion(context),
        ),
        VolverCliente(
          volver: () => widget.controlador.volverAlMenu(context),
        ),
        _crearPresentacion(),
        const SizedBox(height: 12),
        _crearPanelCompras(filtradas, paginas),
      ],
    );
  }

  Widget _crearPanelCompras(List<CompraProducto> filtradas, int paginas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF777777)), borderRadius: BorderRadius.circular(9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BuscadorProductos(
            key: ValueKey(producto),
            alCambiar: (String texto) {
              setState(() {
                busqueda = texto;
                pagina = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 260),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFAAAAAA)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: _crearListadoCompras(filtradas),
          ),
          PaginacionCompras(
            pagina: pagina,
            paginas: paginas,
            alCambiar: (int numero) {
              setState(() {
                pagina = numero;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _crearSelectorProducto() {
    final ProductoListado? seleccionado = producto;
    if (seleccionado == null) {
      return TextButton(
        onPressed: _seleccionar,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        child: const Text('SELECCIONE PRODUCTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _seleccionar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ImagenProducto(producto: seleccionado, tamano: 48),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(seleccionado.nombre,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Text('Stock actual', style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text('${seleccionado.stock} Unidades',
                  style: const TextStyle(color: Color(0xFF168E88), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Cambiar producto',
                  style: TextStyle(fontSize: 11, decoration: TextDecoration.underline)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearListadoCompras(List<CompraProducto> filtradas) {
    if (producto == null) return const SizedBox.shrink();
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (errorCarga != null) {
      return ErrorConsultaCompra(
        mensaje: errorCarga!,
        sesionVencida: false,
        reintentar: _cargar,
        iniciarSesion: () => widget.controlador.cerrarSesion(context),
      );
    }
    if (compras.isEmpty) {
      return const Center(
        child: Text('No se encontraron compras para este producto.', textAlign: TextAlign.center),
      );
    }
    if (filtradas.isEmpty) {
      return const Center(
        child: Text('No se encontraron compras para esta búsqueda.', textAlign: TextAlign.center),
      );
    }
    final List<CompraProducto> visibles = filtradas
        .skip((pagina - 1) * comprasPorPagina)
        .take(comprasPorPagina)
        .toList();
    // Las cuatro columnas conservan su lectura con desplazamiento horizontal
    // en celulares estrechos o cuando el usuario amplía el texto.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double escala = MediaQuery.textScalerOf(context).scale(14) / 14;
        final double minimo = 360 * escala;
        final double ancho = constraints.maxWidth < minimo
            ? minimo
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: ancho,
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text('FECHA', style: TextStyle(fontSize: 10)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('CANTIDAD', style: TextStyle(fontSize: 10)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('PRECIO', style: TextStyle(fontSize: 10)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text('CLIENTE', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
                for (final CompraProducto compra in visibles) _crearFilaCompra(compra),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _crearFilaCompra(CompraProducto compra) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: FechaCompraCliente(fecha: compra.fechaCompra),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${compra.cantidadProducto}', style: const TextStyle(fontSize: 12)),
                const Text('unidades', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(formatearImporte(compra.precioUnitario),
                style: const TextStyle(fontSize: 11, color: Color(0xFF168E88))),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(compra.correoCliente, style: const TextStyle(fontSize: 11)),
                Text(compra.nombreCliente, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(
    BuildContext context,
    List<CompraProducto> filtradas,
    int paginas,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _crearEstructuraPantalla(context, filtradas, paginas),
        ),
      ),
    );
  }

  Widget _crearPresentacion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: turquesa, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Histórico de Compras',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final Widget seleccion = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vea el detalle de compras del producto seleccionado',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 20),
                  _crearSelectorProducto(),
                ],
              );
              final Widget ilustracion = Image.asset(
                'assets/Iconos/IconoAdmin.png',
                width: 115,
                height: 135,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              );
              if (constraints.maxWidth < 310 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    seleccion,
                    Align(alignment: Alignment.centerRight, child: ilustracion),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: seleccion),
                  const SizedBox(width: 8),
                  ilustracion,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
