import 'package:flutter/material.dart';

class PresentacionCliente extends StatelessWidget {
  const PresentacionCliente({
    super.key,
    required this.titulo,
    required this.descripcion,
  });

  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF50BDB5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool apilar =
              constraints.maxWidth < 270 ||
              MediaQuery.textScalerOf(context).scale(12) > 16;
          final Widget texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                descripcion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.15,
                ),
              ),
            ],
          );
          final Widget imagen = Image.asset(
            'assets/Iconos/PanelCliente.png',
            width: 135,
            height: 145,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          );
          if (apilar) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  texto,
                  Align(alignment: Alignment.centerRight, child: imagen),
                ],
              ),
            );
          }
          return Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 172),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 128, 24),
                  child: texto,
                ),
              ),
              Positioned(right: 2, bottom: 4, child: imagen),
            ],
          );
        },
      ),
    );
  }
}
