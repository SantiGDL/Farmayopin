import 'package:flutter/material.dart';

import '../dtos/producto_listado.dart';
import 'imagen_producto.dart';
import '../utils/formatear_importe.dart';

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
