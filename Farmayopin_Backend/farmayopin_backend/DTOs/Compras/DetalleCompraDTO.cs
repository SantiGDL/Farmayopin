using farmayopin_backend.DTOs.Productos;

namespace farmayopin_backend.DTOs.Compras;

public class DetalleCompraDTO
{
    public int Id { get; set; }
    public DateTime FechaCompra { get; set; }
    public List<LineaCompraDTO> Lineas { get; set; } = new List<LineaCompraDTO>();
    public int CantidadProductos { get; set; }
    public decimal Subtotal { get; set; }
    public decimal Envio { get; set; }
    public decimal Total { get; set; }
}

public class LineaCompraDTO
{
    public int Id { get; set; }
    // Nombre y precio son los históricos; los demás datos vienen del producto.
    public ProductoDTO Producto { get; set; }
    public int Cantidad { get; set; }
    public decimal Subtotal { get; set; }

    public LineaCompraDTO(int id, ProductoDTO producto, int cantidad)
    {
        Id = id;
        Producto = producto;
        Cantidad = cantidad;
        Subtotal = producto.Precio * cantidad;
    }
}
