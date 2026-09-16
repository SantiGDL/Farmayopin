// Datos de una fila del listado. No dibuja componentes ni navega.
// Los campos con nombre se agregaron para el detalle del producto: son
// opcionales para no romper los llamados existentes con solo posicionales.
class ProductoListado {
  const ProductoListado(
    this.nombre,
    this.descripcion,
    this.precio,
    this.stock,
    this.categoria, {
    this.id = 0,
    this.codigo = '',
    this.fotoUrl,
    this.unidad = '',
  });

  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final int id;
  final String codigo;
  final String? fotoUrl;
  final String unidad;

  //Conversion del Json que me viene del Backend (ProductoDTO) a DTO del front:
  factory ProductoListado.fromJson(Map<String, dynamic> datosBack) 
  {
    return ProductoListado(
      datosBack['nombre'] as String,
      datosBack['detalle'] as String,
      (datosBack['precio'] as num).toDouble(),
      datosBack['stock'] as int,
      datosBack['categoria'] as String? ?? 'Sin categoría',
      id: datosBack['id'] as int,
      codigo: datosBack['codigo'] as String,
      fotoUrl: datosBack['fotoUrl'] as String?,
      unidad: datosBack['unidad'] as String? ?? '',
    );
  }
}
