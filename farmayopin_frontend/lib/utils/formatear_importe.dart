// Formato visual en pesos. Los importes del carrito se calculan en el backend.
String formatearImporte(double importe) {
  final List<String> partes = importe.toStringAsFixed(2).split('.');
  final String entero = partes[0];
  final StringBuffer texto = StringBuffer(r'$');
  for (int i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) {
      texto.write('.');
    }
    texto.write(entero[i]);
  }
  if (partes[1] != '00') {
    texto.write(',${partes[1]}');
  }
  return texto.toString();
}
