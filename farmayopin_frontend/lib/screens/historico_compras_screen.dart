import '../widgets/paginacion_compras.dart';
import '../widgets/encabezado_cliente.dart';
import '../widgets/presentacion_cliente.dart';
import '../widgets/buscador_productos.dart';
import '../widgets/volver_cliente.dart';
import '../widgets/fecha_compra_cliente.dart';
import '../widgets/error_consulta_compra.dart';
import '../utils/formatear_importe.dart';
import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';
import '../dtos/resumen_compra.dart';
import '../servicios/servicio_cliente.dart';

// ================== ESTRUCTURA Y LÓGICA ==================

class HistoricoComprasScreen extends StatefulWidget {
  const HistoricoComprasScreen({
    super.key,
    this.controlador = const ControladorCliente(),
  });
  final ControladorCliente controlador;

  @override
  State<HistoricoComprasScreen> createState() => _HistoricoComprasScreenState();
}

class _HistoricoComprasScreenState extends State<HistoricoComprasScreen> {
  List<ResumenCompra> compras = [];
  bool cargando = true;
  bool sesionVencida = false;
  String? errorCarga;
  String busqueda = '';
  int pagina = 1;

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
      final List<ResumenCompra> recibidas = await widget.controlador
          .cargarHistorico();
      if (!mounted) return;
      setState(() {
        compras = recibidas;
        pagina = 1;
      });
    } on SesionClienteVencida {
      if (!mounted) return;
      setState(() {
        sesionVencida = true;
        errorCarga = 'Volvé a iniciar sesión para consultar tus compras.';
      });
    } on ErrorOperacionCliente catch (error) {
      if (!mounted) return;
      setState(() { errorCarga = error.mensaje; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorCarga = 'No se pudieron cargar tus compras. Revisá la conexión e intentá nuevamente.';
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
        child: _crearContenidoCentrado(context),
      ),
    );
  }

  Widget _crearEstructuraPantalla(BuildContext context) {
    return Column(
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
          titulo: 'Histórico de compras',
          descripcion: 'Consultá tus compras anteriores, su estado y los detalles de cada pedido de forma fácil y segura.',
        ),
        const SizedBox(height: 12),
        _crearPanelCompras(),
      ],
    );
  }

  Widget _crearPanelCompras() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF777777)), borderRadius: BorderRadius.circular(9)),
      child: Column(
        children: [
          BuscadorProductos(
            alCambiar: (String texto) {
              setState(() {
                busqueda = texto;
                pagina = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          if (compras.any((compra) => compra.desdeCopiaLocal))
            const Padding(padding: EdgeInsets.all(8), child: Text('Sin conexión con el servidor. Mostrando la última copia local.')),
          _crearListadoCompras(),
        ],
      ),
    );
  }

  Widget _crearListadoCompras() {
    if (cargando) {
      return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator());
    }
    if (errorCarga != null) {
      return ErrorConsultaCompra(
        mensaje: errorCarga!,
        sesionVencida: sesionVencida,
        reintentar: _cargar,
        iniciarSesion: () => widget.controlador.cerrarSesion(context),
      );
    }
    if (compras.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Todavía no realizaste compras.', textAlign: TextAlign.center),
      );
    }
    final List<ResumenCompra> filtradas = widget.controlador.filtrarCompras(
      compras,
      busqueda,
    );
    if (filtradas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No se encontraron compras.', textAlign: TextAlign.center),
      );
    }
    final List<ResumenCompra> visibles = widget.controlador.paginaCompras(
      filtradas,
      pagina,
    );
    final int paginas = (filtradas.length / ControladorCliente.comprasPorPagina)
        .ceil();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFAAAAAA)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Fecha', style: TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Pedido /\nProducto', style: TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Total', style: TextStyle(fontSize: 11)),
                  ),
                  SizedBox(width: 28),
                ],
              ),
              for (final ResumenCompra compra in visibles) _crearFilaCompra(compra),
            ],
          ),
        ),
        if (paginas > 1) _crearPaginacion(paginas),
      ],
    );
  }

  Widget _crearFilaCompra(ResumenCompra compra) {
    final String pedido = widget.controlador.identificadorPedido(compra.id);
    return InkWell(
      onTap: () => widget.controlador.verDetalleCompra(context, compra.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: FechaCompraCliente(fecha: compra.fechaCompra),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pedido, style: const TextStyle(fontSize: 11, color: Color(0xFF168E88))),
                  Text('${compra.cantidadProductos} productos',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF50BDB5))),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(formatearImporte(compra.precioTotal),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF168E88))),
            ),
            IconButton(
              tooltip: 'Ver compra $pedido',
              onPressed: () =>
                  widget.controlador.verDetalleCompra(context, compra.id),
              icon: const Icon(Icons.chevron_right, size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _crearPaginacion(int paginas) {
    return PaginacionCompras(pagina: pagina, paginas: paginas, alCambiar: (int numero) {
      setState(() { pagina = numero; });
    });
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _crearEstructuraPantalla(context),
        ),
      ),
    );
  }
}
