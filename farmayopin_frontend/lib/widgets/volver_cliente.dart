import 'package:flutter/material.dart';

class VolverCliente extends StatelessWidget {
  const VolverCliente({super.key, required this.volver});
  final VoidCallback? volver;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: volver,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF199F98)),
      ),
    );
  }
}
