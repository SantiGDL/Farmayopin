import 'producto_listado.dart';

class LineaCompra {
  const LineaCompra(this.id, this.producto, this.cantidad, this.subtotal);

  final int id;
  // El API coloca aquí nombre y precio históricos, junto con datos visuales
  // del producto original. No se usa para modificar el producto ni el carrito.
  final ProductoListado producto;
  final int cantidad;
  final double subtotal;

  factory LineaCompra.fromJson(Map<String, dynamic> datos) {
    return LineaCompra(
      datos['id'] as int,
      ProductoListado.fromJson(datos['producto'] as Map<String, dynamic>),
      datos['cantidad'] as int,
      (datos['subtotal'] as num).toDouble(),
    );
  }
}

class DetalleCompra {
  const DetalleCompra(
    this.id,
    this.fechaCompra,
    this.lineas,
    this.cantidadProductos,
    this.subtotal,
    this.envio,
    this.total,
  );

  final int id;
  final DateTime fechaCompra;
  final List<LineaCompra> lineas;
  final int cantidadProductos;
  final double subtotal;
  final double envio;
  final double total;

  factory DetalleCompra.fromJson(Map<String, dynamic> datos) {
    final List<LineaCompra> lineas = [];
    for (final dynamic linea in datos['lineas'] as List<dynamic>) {
      lineas.add(LineaCompra.fromJson(linea as Map<String, dynamic>));
    }
    return DetalleCompra(
      datos['id'] as int,
      DateTime.parse(datos['fechaCompra'] as String).toLocal(),
      lineas,
      datos['cantidadProductos'] as int,
      (datos['subtotal'] as num).toDouble(),
      (datos['envio'] as num).toDouble(),
      (datos['total'] as num).toDouble(),
    );
  }
}
