import 'package:flutter/material.dart';

import '../dtos/carrito_cliente.dart';
import '../utils/formatear_importe.dart';

class ResumenCarritoCliente extends StatelessWidget {
  const ResumenCarritoCliente({
    super.key,
    required this.carrito,
    this.esConfirmacion = false,
  });
  final CarritoCliente carrito;
  final bool esConfirmacion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          if (esConfirmacion) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resumen de pago',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _importe(
            'Subtotal (${carrito.cantidadProductos} productos)',
            carrito.subtotal,
            false,
          ),
          const SizedBox(height: 6),
          _importe('Envío', carrito.envio, false),
          const Divider(),
          _importe(
            esConfirmacion ? 'Total a pagar' : 'Total',
            carrito.total,
            true,
          ),
        ],
      ),
    );
  }

  Widget _importe(String etiqueta, double? valor, bool destacar) {
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: destacar ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valor == null ? 'A confirmar' : formatearImporte(valor),
          style: const TextStyle(fontSize: 11, color: Color(0xFF168E88)),
        ),
      ],
    );
  }
}
