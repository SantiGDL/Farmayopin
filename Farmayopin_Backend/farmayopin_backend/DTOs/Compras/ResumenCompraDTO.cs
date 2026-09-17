namespace farmayopin_backend.DTOs.Compras;

public class ResumenCompraDTO
{
    public int Id { get; set; }
    public DateTime FechaCompra { get; set; }
    public decimal PrecioTotal { get; set; }
    public int CantidadProductos { get; set; }
    public List<string> NombresProductos { get; set; } = new List<string>();
}
