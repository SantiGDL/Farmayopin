import 'dart:typed_data';

import 'package:flutter/material.dart';

class FotoProductoSelector extends StatelessWidget {
  const FotoProductoSelector({
    super.key,
    required this.bytes,
    required this.nombre,
    required this.seleccionar,
    required this.quitar,
  });

  final Uint8List? bytes;
  final String? nombre;
  final VoidCallback? seleccionar;
  final VoidCallback? quitar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: seleccionar,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            backgroundColor: const Color(0xFFF5FAF9),
          ),
          child: Column(
            children: [
              if (bytes != null)
                Image.memory(
                  bytes!,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) {
                    return const Text('No se pudo mostrar la vista previa.');
                  },
                )
              else
                const Icon(Icons.cloud_upload_outlined, size: 36),
              const SizedBox(height: 8),
              Text(nombre ?? 'Seleccioná una foto del producto (opcional)'),
              const SizedBox(height: 4),
              const Text('JPG o PNG · Máximo 5 MB'),
            ],
          ),
        ),
        if (bytes != null)
          TextButton(onPressed: quitar, child: const Text('Quitar foto')),
      ],
    );
  }
}
