import 'package:flutter/material.dart';

import '../controladores/controlador_cliente.dart';

// La pantalla dibuja. El controlador recibe las acciones de los botones.
// ================== ESTRUCTURA Y LÓGICA ==================

class ClienteHomeScreen extends StatelessWidget {
  const ClienteHomeScreen({super.key, this.controlador = const ControladorCliente()});

  final ControladorCliente controlador;
  static const String _iconos = 'assets/Iconos';
  static const Color _turquesa = Color(0xFF50BDB5);
  static const Color _textoSecundario = Color(0xFF929299);

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
        _crearEncabezado(context),
        const SizedBox(height: 24),
        _crearBienvenida(),
        const SizedBox(height: 36),
        _crearOpciones(context),
        const SizedBox(height: 40),
        _crearAccesoHistorico(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _crearOpciones(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dos columnas en celular; una si el espacio disponible es muy pequeño.
        final double ancho = constraints.maxWidth < 330
            ? constraints.maxWidth
            : (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 20,
          children: [
            _crearTarjetaOpcion(
              ancho,
              'Ver Productos',
              'Explore nuestro catálogo de medicamentos, vitaminas y cuidados personal.',
              'VerProductos.png',
              () => controlador.verProductos(context),
            ),
            _crearTarjetaOpcion(
              ancho,
              'Mi Carrito',
              'Revise los productos que agregó a su carrito y continúe su compra',
              'MiCarrito.png',
              () => controlador.verCarrito(context),
            ),
          ],
        );
      },
    );
  }

  Widget _crearAccesoHistorico(BuildContext context) {
    return _crearTarjeta(
      () => controlador.verHistorico(context),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            '$_iconos/IconoHistoricoDeCompras.png',
            width: 70,
            height: 70,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico de Compras',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Text('Ver historial de compras realizadas (Fecha, Cantidad, Cliente).',
                          style: TextStyle(fontSize: 14, color: _textoSecundario, height: 1.2)),
                    ),
                    const SizedBox(width: 8),
                    _crearFlecha(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        // Como max-width en CSS: conserva el diseño de celular en escritorio.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _crearEstructuraPantalla(context),
        ),
      ),
    );
  }

  Widget _crearEncabezado(BuildContext context) {
    // Wrap permite bajar el botón si el ancho o el tamaño del texto lo requiere.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/farmayopin_logo.png',
              width: 100,
              semanticLabel: 'Farmayopin',
            ),
            const Text('Cliente',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        TextButton.icon(
          onPressed: () => controlador.cerrarSesion(context),
          icon: const Icon(Icons.logout, size: 26),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFEEEEEE),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _crearBienvenida() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(18, 22, 8, 12),
      decoration: BoxDecoration(color: _turquesa, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PANEL DE CLIENTE',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenido a Farmayopin',
                        style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, height: 1.15)),
                    SizedBox(height: 16),
                    Text(
                      'Explora nuestros productos, agregalos al carrito y gestiona tus compras de forma fácil y segura.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Flexible mantiene la ilustración dentro de pantallas angostas.
              Flexible(
                child: Image.asset(
                  '$_iconos/PanelCliente.png',
                  height: 182,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Parámetros posicionales: ancho, título, descripción, imagen y acción.
  Widget _crearTarjetaOpcion(
    double ancho,
    String titulo,
    String descripcion,
    String icono,
    VoidCallback accion,
  ) {
    return SizedBox(
      width: ancho,
      child: _crearTarjeta(
        accion,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              '$_iconos/$icono',
              width: 94,
              height: 94,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Altura mínima para alinear las tarjetas, sin recortar texto ampliado.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Text(descripcion,
                  style: const TextStyle(fontSize: 14, color: _textoSecundario, height: 1.2)),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: _crearFlecha()),
          ],
        ),
      ),
    );
  }

  Widget _crearTarjeta(VoidCallback accion, Widget contenido) {
    // Material dibuja el borde y la sombra; InkWell responde a clics y toques.
    final BorderRadius borde = BorderRadius.circular(22);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        elevation: 5,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: borde, side: const BorderSide(color: Color(0xFFE5E5E5))),
        child: InkWell(
          onTap: accion,
          borderRadius: borde,
          child: Padding(padding: const EdgeInsets.all(10), child: contenido),
        ),
      ),
    );
  }

  Widget _crearFlecha() {
    return Image.asset(
      '$_iconos/Flecha.png',
      width: 33,
      height: 31,
      excludeFromSemantics: true,
    );
  }
}
