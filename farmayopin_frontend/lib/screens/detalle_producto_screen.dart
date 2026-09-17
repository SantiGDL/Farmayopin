import 'package:flutter/material.dart';

import '../controladores/controlador_admin.dart';
import '../dtos/producto_listado.dart';
import '../config/api_config.dart';

// Muestra los datos reales de un producto. La lista los recibe por Navigator
// y esta pantalla solo los dibuja; no vuelve a consultarlos al backend.
class DetalleProductoScreen extends StatelessWidget {
  const DetalleProductoScreen({super.key, required this.producto, this.esCliente = false});

  final ProductoListado producto;
  final bool esCliente;

  final ControladorAdmin controlador = const ControladorAdmin();

  static const Color _turquesa = Color(0xFF50BDB5);
  static const Color _textoSecundario = Color(0xFF929299);
  static const Color _cajaIcono = Color(0xFFEAFBF7);
  static const String _iconos = 'assets/Iconos';

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
                  _encabezado(context),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => controlador.volverAlMenu(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ),
                  _presentacion(),
                  const SizedBox(height: 22),
                  _imagenProducto(),
                  const SizedBox(height: 18),
                  _tituloYPrecio(),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _informacion(),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _descripcion(),
                  const SizedBox(height: 24),
                  _acciones(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context) {
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
            Text(
              esCliente ? 'Cliente' : 'Administrador',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => controlador.cerrarSesion(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFEEEEEE),
          ),
        ),
      ],
    );
  }

  Widget _presentacion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _turquesa,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del Producto',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Consultá la información detallada del producto seleccionado.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Image.asset(
              '$_iconos/IconoAdmin.png',
              height: 100,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }

  // Regla del enunciado: FotoUrl válida => Image.network; si es nula, está
  // vacía o falla al cargar => imagen local por defecto.
  Widget _imagenProducto() {
    final String? url = producto.fotoUrl;
    final bool tieneUrl = url != null && url.trim().isNotEmpty && !url.startsWith('assets/');
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: tieneUrl
            ? Image.network(
                ApiConfig.uri(url.trim()).toString(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _imagenPorDefecto();
                },
                loadingBuilder: (context, child, progreso) {
                  if (progreso == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              )
            : _imagenPorDefecto(),
      ),
    );
  }

  Widget _imagenPorDefecto() {
    return Image.asset(
      'assets/images/producto_default.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }

  Widget _tituloYPrecio() {
    final bool enStock = producto.stock > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              '\$${_formatearPrecio(producto.precio)}',
              style: const TextStyle(
                color: _turquesa,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: enStock
                    ? const Color(0xFFE3F8ED)
                    : const Color(0xFFF3E3E3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enStock ? Icons.check_circle : Icons.cancel,
                    size: 15,
                    color: enStock ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    enStock ? 'En Stock' : 'Sin Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: enStock
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Separador de miles simple, sin agregar el paquete intl al proyecto.
  // Separa los miles y conserva los centavos cuando el precio los tiene.
  String _formatearPrecio(double precio)
  {
    final List<String> partes = precio.toStringAsFixed(2).split('.');
    final String digitos = partes[0];
    final StringBuffer resultado = StringBuffer();
    for (int i = 0; i < digitos.length; i++) {
      final int posicionDesdeElFinal = digitos.length - i;
      if (i > 0 && posicionDesdeElFinal % 3 == 0) {
        resultado.write('.');
      }
      resultado.write(digitos[i]);
    }
    if (partes[1] != '00')
    {
      resultado.write(',${partes[1]}');
    }
    return resultado.toString();
  }

  Widget _informacion() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double ancho = constraints.maxWidth < 300
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 18,
          children: [
            SizedBox(
              width: ancho,
              child: _infoItem(
                Icons.sell_outlined,
                'Categoría',
                producto.categoria,
              ),
            ),
            SizedBox(
              width: ancho,
              child: _infoItem(
                Icons.qr_code_2_outlined,
                'Código',
                producto.codigo,
              ),
            ),
            SizedBox(
              width: ancho,
              child: _infoItem(
                Icons.inventory_2_outlined,
                'Stock Disponible',
                '${producto.stock} Unidades',
              ),
            ),
            SizedBox(
              width: ancho,
              child: _infoItem(
                Icons.medication_outlined,
                'Unidad de medida',
                producto.unidad,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoItem(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cajaIcono,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: _turquesa, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(fontSize: 12, color: _textoSecundario),
              ),
              const SizedBox(height: 2),
              Text(
                valor.isEmpty ? '-' : valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _descripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description_outlined, color: _turquesa, size: 20),
            SizedBox(width: 8),
            Text(
              'Descripción',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          producto.descripcion,
          style: const TextStyle(fontSize: 13, color: _textoSecundario, height: 1.4),
        ),
      ],
    );
  }

  Widget _acciones(BuildContext context) {
    if (esCliente) {
      return OutlinedButton.icon(
        onPressed: () { controlador.volverAlMenu(context); },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Volver a productos'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compacto = constraints.maxWidth < 340;
        final Widget editar = FilledButton.icon(
          onPressed: () => controlador.editarProducto(context, producto),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar producto'),
          style: FilledButton.styleFrom(
            backgroundColor: _turquesa,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        final Widget historico = OutlinedButton.icon(
          onPressed: () =>
              controlador.mostrarPendiente(context, 'Histórico de compras'),
          icon: const Icon(Icons.history),
          label: const Text('Ver histórico de compras'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _turquesa),
            foregroundColor: _turquesa,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        if (compacto) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: editar),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: historico),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: editar),
            const SizedBox(width: 12),
            Expanded(child: historico),
          ],
        );
      },
    );
  }
}
