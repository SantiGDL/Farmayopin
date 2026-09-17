import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';
import '../dtos/carrito_cliente.dart';
import '../servicios/servicio_cliente.dart';
import '../widgets/productos_cliente_widgets.dart';

class ConfirmarCompraScreen extends StatefulWidget {
  const ConfirmarCompraScreen({
    super.key,
    this.controlador = const ControladorCliente(),
  });
  final ControladorCliente controlador;

  @override
  State<ConfirmarCompraScreen> createState() => _ConfirmarCompraScreenState();
}

class _ConfirmarCompraScreenState extends State<ConfirmarCompraScreen> {
  CarritoCliente? carrito;
  bool cargando = true;
  bool confirmando = false;
  bool sesionVencida = false;
  String? errorCarga;
  String? metodo;

  @override
  void initState() {
    super.initState();
    _cargarCarrito();
  }

  Future<void> _cargarCarrito() async {
    setState(() {
      cargando = true;
      errorCarga = null;
      sesionVencida = false;
    });
    try {
      final CarritoCliente recibido = await widget.controlador.cargarCarrito();
      if (mounted) {
        setState(() {
          carrito = recibido;
        });
      }
    } on SesionClienteVencida {
      if (mounted) {
        setState(() {
          sesionVencida = true;
          errorCarga = 'Volvé a iniciar sesión para confirmar tu compra.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorCarga = 'No se pudo cargar el resumen. Revisá la conexión e intentá nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  Future<void> _confirmar() async {
    if (confirmando) return;
    setState(() {
      confirmando = true;
    });
    final bool exito = await widget.controlador.confirmarCompra(
      context,
      metodo,
    );
    if (!mounted || exito) return;
    setState(() {
      confirmando = false;
    });
    // Un conflicto de stock o una respuesta perdida requiere volver a leer
    // el carrito antes de permitir otro intento.
    if (metodo != null) await _cargarCarrito();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !confirmando,
      child: Scaffold(
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
                      cerrarSesion: confirmando
                          ? null
                          : () => widget.controlador.cerrarSesion(context),
                    ),
                    VolverCliente(
                      volver: confirmando
                          ? null
                          : () => widget.controlador.volver(context),
                    ),
                    const PresentacionCliente(
                      titulo: 'Confirmar compra',
                      descripcion: 'Revisá tu pedido, elegí tu método de pago y confirmá para completar tu compra de forma segura.',
                    ),
                    const SizedBox(height: 14),
                    _contenido(),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: confirmando
                          ? null
                          : () => widget.controlador.volver(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF199F98),
                        side: const BorderSide(color: Color(0xFF199F98)),
                      ),
                      child: const Text('Volver al carrito'),
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
          TextButton(
            onPressed: sesionVencida
                ? () => widget.controlador.cerrarSesion(context)
                : _cargarCarrito,
            child: Text(sesionVencida ? 'Iniciar sesión' : 'Reintentar'),
          ),
        ],
      );
    }
    final CarritoCliente actual = carrito!;
    if (actual.lineas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Tu carrito está vacío.', textAlign: TextAlign.center),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _resumenProductos(actual),
        const SizedBox(height: 12),
        _metodosPago(),
        const SizedBox(height: 12),
        ResumenCarritoCliente(carrito: actual, esConfirmacion: true),
        const SizedBox(height: 14),
        if (confirmando) const LinearProgressIndicator(),
        FilledButton.icon(
          onPressed: confirmando ? null : _confirmar,
          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          label: Text(confirmando ? 'Confirmando...' : 'Confirmar pago'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF199F98),
            shape: const StadiumBorder(),
          ),
        ),
      ],
    );
  }

  Widget _resumenProductos(CarritoCliente actual) {
    return _seccion(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen de Compra',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Nombre',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 54,
                child: Text(
                  'Cantidad',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 62,
                child: Text(
                  'Precio',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          for (final LineaCarritoCliente linea in actual.lineas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  ImagenProducto(producto: linea.producto, tamano: 32),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      linea.producto.nombre,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 54,
                    child: Text(
                      'x${linea.cantidad}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: Text(
                      formatearImporte(linea.subtotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metodosPago() {
    // El dominio no tiene un atributo para el método: selección visual única.
    return _seccion(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Método de pago',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _metodo('Tarjeta', Icons.credit_card),
              _metodo('Transferencia', Icons.account_balance_outlined),
              _metodo('Efectivo', Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metodo(String nombre, IconData icono) {
    final bool seleccionado = metodo == nombre;
    return Semantics(
      checked: seleccionado,
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        onPressed: confirmando
            ? null
            : () => setState(() {
                metodo = nombre;
              }),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: seleccionado
              ? const Color(0xFFD3FDF0)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  seleccionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 14,
                  color: const Color(0xFF199F98),
                ),
                const SizedBox(width: 5),
                Icon(icono, size: 20),
              ],
            ),
            Text(nombre, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _seccion(Widget contenido) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: contenido,
    );
  }
}
