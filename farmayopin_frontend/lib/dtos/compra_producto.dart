class CompraProducto {
  const CompraProducto(
    this.fechaCompra,
    this.cantidadProducto,
    this.precioUnitario,
    this.nombreCliente,
    this.correoCliente,
  );

  final DateTime fechaCompra;
  final int cantidadProducto;
  final double precioUnitario;
  final String nombreCliente;
  final String correoCliente;

  factory CompraProducto.fromJson(Map<String, dynamic> datos) {
    return CompraProducto(
      DateTime.parse(datos['fechaCompra'] as String).toLocal(),
      datos['cantidadProducto'] as int,
      (datos['precioUnitario'] as num).toDouble(),
      datos['nombreCliente'] as String,
      datos['correoCliente'] as String,
    );
  }
}
