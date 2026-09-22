import 'package:flutter/material.dart';

class ErrorConsultaCompra extends StatelessWidget {
  const ErrorConsultaCompra({
    super.key,
    required this.mensaje,
    required this.sesionVencida,
    required this.reintentar,
    required this.iniciarSesion,
  });
  final String mensaje;
  final bool sesionVencida;
  final VoidCallback reintentar;
  final VoidCallback iniciarSesion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(mensaje, textAlign: TextAlign.center),
          TextButton(
            onPressed: sesionVencida ? iniciarSesion : reintentar,
            child: Text(sesionVencida ? 'Iniciar sesión' : 'Reintentar'),
          ),
        ],
      ),
    );
  }
}
