using farmayopin_backend.DTOs.Productos;

namespace farmayopin_backend.DTOs.Carritos;

public class LineaDeCarritoDTO
{
    public int Id { get; set; }
    public ProductoDTO Producto { get; set; }
    public int Cantidad { get; set; }
    public decimal Subtotal { get; set; }

    public LineaDeCarritoDTO(int id, ProductoDTO producto, int cantidad)
    {
        Id = id;
        Producto = producto;
        Cantidad = cantidad;
        Subtotal = producto.Precio * cantidad;
    }
}
