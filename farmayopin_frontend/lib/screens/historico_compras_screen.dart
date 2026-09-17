import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';
import '../dtos/resumen_compra.dart';
import '../servicios/servicio_cliente.dart';
import '../widgets/compras_cliente_widgets.dart';
import '../widgets/productos_cliente_widgets.dart';

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
                    titulo: 'Histórico de compras',
                    descripcion: 'Consultá tus compras anteriores, su estado y los detalles de cada pedido de forma fácil y segura.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF777777)),
                      borderRadius: BorderRadius.circular(9),
                    ),
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
                        _contenido(),
                      ],
                    ),
                  ),
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
        child: CircularProgressIndicator(),
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
    if (compras.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Todavía no realizaste compras.',
          textAlign: TextAlign.center,
        ),
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
                    child: Text(
                      'Pedido /\nProducto',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Total', style: TextStyle(fontSize: 11)),
                  ),
                  SizedBox(width: 28),
                ],
              ),
              for (final ResumenCompra compra in visibles) _fila(compra),
            ],
          ),
        ),
        if (paginas > 1) _paginacion(paginas),
      ],
    );
  }

  Widget _fila(ResumenCompra compra) {
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
                  Text(
                    pedido,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF168E88),
                    ),
                  ),
                  Text(
                    '${compra.cantidadProductos} productos',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF50BDB5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                formatearImporte(compra.precioTotal),
                style: const TextStyle(fontSize: 11, color: Color(0xFF168E88)),
              ),
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

  Widget _paginacion(int paginas) {
    final List<Widget> botones = [];
    int anterior = 0;
    for (int numero = 1; numero <= paginas; numero++) {
      if (numero != 1 && numero != paginas && (numero - pagina).abs() > 1) {
        continue;
      }
      if (anterior > 0 && numero - anterior > 1) botones.add(const Text('...'));
      final int seleccionada = numero;
      botones.add(
        ChoiceChip(
          label: Text('$numero'),
          selected: numero == pagina,
          showCheckmark: false,
          selectedColor: const Color(0xFF50BDB5),
          visualDensity: VisualDensity.compact,
          onSelected: (bool valor) => setState(() {
            pagina = seleccionada;
          }),
        ),
      );
      anterior = numero;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: pagina > 1
                ? () => setState(() {
                    pagina--;
                  })
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...botones,
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: pagina < paginas
                ? () => setState(() {
                    pagina++;
                  })
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
