import 'package:flutter/material.dart';

import '../controladores/controlador_formulario_producto.dart';

// Campos comunes de crear y editar; cada pantalla conserva su composición.
class CamposProducto extends StatelessWidget {
  const CamposProducto({
    super.key,
    required this.controlador,
    this.habilitado = true,
    this.esEdicion = false,
  });
  final ControladorFormularioProducto controlador;
  final bool habilitado;
  final bool esEdicion;

  static const Map<int, String> categorias = {
    0: 'Analgésicos',
    1: 'Higiene personal',
    2: 'Primeros auxilios',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campo(
          'Nombre del producto',
          controlador.nombre,
          Icons.sell_outlined,
          validar: controlador.validarObligatorio,
          ayuda: 'Ingresá el nombre del producto',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _campo(
                'Precio',
                controlador.precio,
                Icons.attach_money,
                validar: controlador.validarPrecio,
                ayuda: '0,00',
                teclado: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _campo(
                'Stock',
                controlador.stock,
                Icons.inventory_2_outlined,
                validar: controlador.validarStock,
                ayuda: '0',
                teclado: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Categoría'),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          // Al seleccionar otro producto hay que reemplazar el valor del campo.
          key: ValueKey('${habilitado}_${controlador.codigo.text}'),
          initialValue: controlador.categoria,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Seleccioná una categoría',
            prefixIcon: Icon(
              Icons.category_outlined,
              size: 20,
              color: Colors.grey,
            ),
          ),
          items: [
            for (final entrada in categorias.entries)
              DropdownMenuItem(value: entrada.key, child: Text(entrada.value)),
          ],
          validator: controlador.validarCategoria,
          onChanged: habilitado ? controlador.cambiarCategoria : null,
        ),
        const SizedBox(height: 16),
        _campo(
          esEdicion ? 'Detalle' : 'Descripción',
          controlador.detalle,
          Icons.description_outlined,
          ayuda: 'Ingresá una descripción del producto…',
          lineas: 3,
          teclado: TextInputType.multiline,
        ),
      ],
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController campo,
    IconData icono, {
    String? Function(String?)? validar,
    String? ayuda,
    int lineas = 1,
    TextInputType teclado = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta),
        const SizedBox(height: 6),
        TextFormField(
          controller: campo,
          enabled: habilitado,
          validator: validar,
          maxLines: lineas,
          keyboardType: teclado,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: esEdicion ? null : ayuda,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            prefixIcon: Icon(icono, size: 20, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
