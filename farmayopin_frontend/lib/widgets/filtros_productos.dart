import 'package:flutter/material.dart';

import '../dtos/producto_listado.dart';

class FiltrosProductos extends StatelessWidget {
  const FiltrosProductos({
    super.key,
    required this.productos,
    required this.categoria,
    required this.alSeleccionar,
    this.soloCategoriasDisponibles = false,
  });

  final List<ProductoListado> productos;
  final String categoria;
  final ValueChanged<String> alSeleccionar;
  final bool soloCategoriasDisponibles;

  @override
  Widget build(BuildContext context) {
    // Solo ofrecemos categorías presentes en los productos del backend.
    final List<String> categorias = ['Todos'];
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
