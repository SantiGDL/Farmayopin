import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../dtos/producto_listado.dart';

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
