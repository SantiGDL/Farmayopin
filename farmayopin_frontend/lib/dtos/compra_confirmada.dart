class CompraConfirmada {
  const CompraConfirmada(this.compraId, this.subtotal, this.envio, this.total);

  final int compraId;
  final double subtotal;
  final double envio;
  final double total;

  factory CompraConfirmada.fromJson(Map<String, dynamic> datos) {
    return CompraConfirmada(
      (datos['compraId'] as num).toInt(),
      (datos['subtotal'] as num).toDouble(),
      (datos['envio'] as num).toDouble(),
      (datos['total'] as num).toDouble(),
    );
  }
}
