namespace farmayopin_backend.DTOs.Compras;

public class CompraProductoDTO
{
    public DateTime FechaCompra { get; set; }
    public int CantidadProducto { get; set; }
    public decimal PrecioUnitario { get; set; }
    public string NombreCliente { get; set; } = "";
    public string CorreoCliente { get; set; } = "";
}
