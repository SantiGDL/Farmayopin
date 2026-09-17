namespace farmayopin_backend.DTOs.Carritos;

public class CarritoDTO
{
    public int? Id { get; set; }
    public List<LineaDeCarritoDTO> Lineas { get; set; } = new List<LineaDeCarritoDTO>();
    public int CantidadProductos { get; set; }
    public decimal Subtotal { get; set; }
    // El servicio aplica $700 al carrito con productos y $0 al vacío.
    public decimal? Envio { get; set; }
    public decimal? Total { get; set; }
}
