import 'producto_listado.dart';

class LineaCarritoCliente {
  const LineaCarritoCliente(
    this.id,
    this.producto,
    this.cantidad,
    this.subtotal,
  );

  final int id;
  final ProductoListado producto;
  final int cantidad;
  final double subtotal;

  factory LineaCarritoCliente.fromJson(Map<String, dynamic> datos) {
    final Map<String, dynamic> datosProducto =
        datos['producto'] as Map<String, dynamic>;
    return LineaCarritoCliente(
      datos['id'] as int,
      ProductoListado.fromJson(datosProducto),
      datos['cantidad'] as int,
      (datos['subtotal'] as num).toDouble(),
    );
  }
}

class CarritoCliente {
  const CarritoCliente(
    this.id,
    this.lineas,
    this.cantidadProductos,
    this.subtotal,
    this.envio,
    this.total,
  );

  final int? id;
  final List<LineaCarritoCliente> lineas;
  final int cantidadProductos;
  final double subtotal;
  final double? envio;
  final double? total;

  factory CarritoCliente.fromJson(Map<String, dynamic> datos) {
    final List<dynamic> datosLineas = datos['lineas'] as List<dynamic>;
    final List<LineaCarritoCliente> lineas = [];
    for (final dynamic dato in datosLineas) {
      final Map<String, dynamic> datosLinea = dato as Map<String, dynamic>;
      lineas.add(LineaCarritoCliente.fromJson(datosLinea));
    }

    return CarritoCliente(
      datos['id'] as int?,
      lineas,
      datos['cantidadProductos'] as int,
      (datos['subtotal'] as num).toDouble(),
      (datos['envio'] as num?)?.toDouble(),
      (datos['total'] as num?)?.toDouble(),
    );
  }
}
