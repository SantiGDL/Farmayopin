// El endpoint existente identifica el producto por su código, que no se edita.
class EditarProducto {
  const EditarProducto(
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
  final int? categoria;
  final String? fotoUrl;
}
