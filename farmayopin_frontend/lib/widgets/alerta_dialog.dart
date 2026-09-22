import 'package:flutter/material.dart';

// Un mismo diálogo para confirmar operaciones o explicar errores.
class AlertaDialog extends StatelessWidget {
  const AlertaDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.exito,
  });

  final String titulo;
  final String mensaje;
  final bool exito;

  static Future<void> mostrar(
    BuildContext context,
    String titulo,
    String mensaje,
    bool exito,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertaDialog(titulo: titulo, mensaje: mensaje, exito: exito);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        exito ? Icons.check_circle_outline : Icons.error_outline,
        color: exito ? const Color(0xFF00AAA5) : Colors.red,
        size: 48,
      ),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
