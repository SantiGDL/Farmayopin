// Datos que el controlador entrega al servicio para crear un producto.
class CrearProducto {
  const CrearProducto(
    this.codigo,
    this.nombre,
    this.detalle,
    this.precio,
    this.stock,
    this.categoria,
    this.fotoUrl,
  );

  final String codigo;
  final String nombre;
  final String detalle;
  final double precio;
  final int stock;
  final int categoria;
  final String? fotoUrl;
}
