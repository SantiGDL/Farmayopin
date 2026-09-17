namespace farmayopin_backend.DTOs.Carritos;

public class CarritoDTO
{
    public int? Id { get; set; }
    public List<LineaDeCarritoDTO> Lineas { get; set; } = new List<LineaDeCarritoDTO>();
    public int CantidadProductos { get; set; }
    public decimal Subtotal { get; set; }
    // Null indica que el equipo todavía no definió una tarifa de envío.
    public decimal? Envio { get; set; }
    public decimal? Total { get; set; }
}
