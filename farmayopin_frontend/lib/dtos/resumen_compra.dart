class ResumenCompra {
  const ResumenCompra(
    this.id,
    this.fechaCompra,
    this.precioTotal,
    this.cantidadProductos,
    this.nombresProductos, {
    this.desdeCopiaLocal = false,
  });

  final bool desdeCopiaLocal;
  final int id;
  final DateTime fechaCompra;
  final double precioTotal;
  final int cantidadProductos;
  final List<String> nombresProductos;

  factory ResumenCompra.fromJson(Map<String, dynamic> datos) {
    return ResumenCompra(
      datos['id'] as int,
      DateTime.parse(datos['fechaCompra'] as String).toLocal(),
      (datos['precioTotal'] as num).toDouble(),
      datos['cantidadProductos'] as int,
      List<String>.from(datos['nombresProductos'] as List<dynamic>),
      desdeCopiaLocal: datos['desdeCopiaLocal'] == true,
    );
  }
}
