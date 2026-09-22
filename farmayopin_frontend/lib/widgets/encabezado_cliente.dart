import 'package:flutter/material.dart';

class EncabezadoCliente extends StatelessWidget {
  const EncabezadoCliente({super.key, required this.cerrarSesion});

  final VoidCallback? cerrarSesion;

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
