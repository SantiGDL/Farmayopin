import 'package:flutter/material.dart';

class PaginacionCompras extends StatelessWidget {
  const PaginacionCompras({
    super.key,
    required this.pagina,
    required this.paginas,
    required this.alCambiar,
  });
  final int pagina;
  final int paginas;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final List<Widget> botones = [];
    int anterior = 0;
    for (int numero = 1; numero <= paginas; numero++) {
      if (numero != 1 && numero != paginas && (numero - pagina).abs() > 1) {
        continue;
      }
      if (anterior > 0 && numero - anterior > 1) botones.add(const Text('...'));
      final int seleccionada = numero;
      botones.add(
        ChoiceChip(
          label: Text('$numero'),
          selected: numero == pagina,
          showCheckmark: false,
          selectedColor: const Color(0xFF50BDB5),
          visualDensity: VisualDensity.compact,
          onSelected: (bool valor) => alCambiar(seleccionada),
        ),
      );
      anterior = numero;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Página anterior',
            onPressed: pagina > 1 ? () => alCambiar(pagina - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...botones,
          IconButton(
            tooltip: 'Página siguiente',
            onPressed: pagina < paginas ? () => alCambiar(pagina + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
