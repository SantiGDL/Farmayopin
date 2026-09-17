import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../dtos/producto_listado.dart';

// Piezas compartidas por el catálogo y el carrito del diseño del cliente.
class EncabezadoCliente extends StatelessWidget {
  const EncabezadoCliente({super.key, required this.cerrarSesion});

  final VoidCallback cerrarSesion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/farmayopin_logo.png',
              width: 84,
              semanticLabel: 'Farmayopin',
            ),
            const Text(
              'Cliente',
              style: TextStyle(
                color: Color(0xFF929299),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: cerrarSesion,
          icon: const Icon(Icons.logout, size: 23),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFEEEEEE),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class PresentacionCliente extends StatelessWidget {
  const PresentacionCliente({
    super.key,
    required this.titulo,
    required this.descripcion,
  });

  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF50BDB5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool apilar =
              constraints.maxWidth < 270 ||
              MediaQuery.textScalerOf(context).scale(12) > 16;
          final Widget texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                descripcion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ],
          );
          final Widget imagen = Image.asset(
            'assets/Iconos/PanelCliente.png',
            width: 135,
            height: 145,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          );
          if (apilar) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  texto,
                  Align(alignment: Alignment.centerRight, child: imagen),
                ],
              ),
            );
          }
          return Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 172),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 128, 24),
                  child: texto,
                ),
              ),
              Positioned(right: 2, bottom: 4, child: imagen),
            ],
          );
        },
      ),
    );
  }
}

class BuscadorProductos extends StatelessWidget {
  const BuscadorProductos({super.key, required this.alCambiar});

  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: alCambiar,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search, size: 28, color: Colors.black),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 32,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class FiltrosProductos extends StatelessWidget {
  const FiltrosProductos({
    super.key,
    required this.productos,
    required this.categoria,
    required this.alSeleccionar,
  });

  final List<ProductoListado> productos;
  final String categoria;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    // Conservamos los filtros del diseño y añadimos las categorías reales.
    // Vitaminas puede no tener resultados: el enum actual aún no la incluye.
    final List<String> categorias = ['Todos', 'Medicamentos', 'Vitaminas'];
    for (final ProductoListado producto in productos) {
      if (!categorias.contains(producto.categoria)) {
        categorias.add(producto.categoria);
      }
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final String opcion in categorias)
          ChoiceChip(
            label: Text(opcion, style: const TextStyle(fontSize: 10)),
            selected: categoria == opcion,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFD3FDF0),
            side: const BorderSide(color: Color(0xFF50BDB5)),
            shape: const StadiumBorder(),
            onSelected: (bool seleccionado) {
              alSeleccionar(opcion);
            },
          ),
      ],
    );
  }
}

class ImagenProducto extends StatelessWidget {
  const ImagenProducto({super.key, required this.producto, this.tamano = 64});

  final ProductoListado producto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final String ruta = producto.fotoUrl?.trim() ?? '';
    final Widget respaldo = Image.asset(
      'assets/images/producto_default.png',
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
    );
    if (ruta.isEmpty || ruta.startsWith('assets/')) {
      return respaldo;
    }
    return Image.network(
      ApiConfig.uri(ruta).toString(),
      width: tamano,
      height: tamano,
      fit: BoxFit.contain,
      semanticLabel: producto.nombre,
      errorBuilder: (context, error, stackTrace) {
        return respaldo;
      },
    );
  }
}

class TarjetaProductoCliente extends StatelessWidget {
  const TarjetaProductoCliente({
    super.key,
    required this.producto,
    required this.acciones,
    this.esCarrito = false,
  });

  final ProductoListado producto;
  final Widget acciones;
  final bool esCarrito;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFBBBBBB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compacto =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(12) > 16;
          final Widget datos = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                producto.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    formatearImporte(producto.precio),
                    style: const TextStyle(
                      color: Color(0xFF239F98),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stock: ${producto.stock}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (esCarrito) acciones,
                ],
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ImagenProducto(producto: producto, tamano: 62),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: datos),
                  if (!esCarrito && !compacto) ...[
                    const SizedBox(width: 6),
                    acciones,
                  ],
                ],
              ),
              if (!esCarrito && compacto)
                Align(alignment: Alignment.centerRight, child: acciones),
            ],
          );
        },
      ),
    );
  }
}

// Formato visual en pesos. Los importes del carrito se calculan en el backend.
String formatearImporte(double importe) {
  final List<String> partes = importe.toStringAsFixed(2).split('.');
  final String entero = partes[0];
  final StringBuffer texto = StringBuffer(r'$');
  for (int i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) {
      texto.write('.');
    }
    texto.write(entero[i]);
  }
  if (partes[1] != '00') {
    texto.write(',${partes[1]}');
  }
  return texto.toString();
}
