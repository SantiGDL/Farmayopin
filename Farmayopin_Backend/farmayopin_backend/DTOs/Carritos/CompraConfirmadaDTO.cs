namespace farmayopin_backend.DTOs.Carritos;

public class CompraConfirmadaDTO
{
    public int CompraId { get; set; }
    public decimal Subtotal { get; set; }
    public decimal Envio { get; set; }
    public decimal Total { get; set; }
    public string Mensaje { get; set; } = "Compra confirmada correctamente.";
}
