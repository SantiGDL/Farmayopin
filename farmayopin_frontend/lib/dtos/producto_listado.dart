// Datos de una fila del listado. No dibuja componentes ni navega.
class ProductoListado {
  const ProductoListado(
    this.nombre,
    this.descripcion,
    this.precio,
    this.stock,
    this.categoria,
  );

  final String nombre;
  final String descripcion;
  final int precio;
  final int stock;
  final String categoria;
}
