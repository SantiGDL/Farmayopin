import 'package:flutter/material.dart';

class EncabezadoAdmin extends StatelessWidget {
  const EncabezadoAdmin({super.key, required this.cerrarSesion});
  final VoidCallback cerrarSesion;

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Administrador',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: cerrarSesion,
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
}
