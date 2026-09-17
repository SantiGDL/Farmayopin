import 'package:flutter/material.dart';

class FechaCompraCliente extends StatelessWidget {
  const FechaCompraCliente({super.key, required this.fecha});
  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    const List<String> meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    int hora = fecha.hour % 12;
    if (hora == 0) hora = 12;
    final String minutos = fecha.minute.toString().padLeft(2, '0');
    final String periodo = fecha.hour < 12 ? 'am' : 'pm';
    return Tooltip(
      message: '${fecha.day}/${fecha.month}/${fecha.year}',
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD3FDF0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: Color(0xFF174E43),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fecha.day} de ${meses[fecha.month - 1]}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  '$hora:$minutos $periodo',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
