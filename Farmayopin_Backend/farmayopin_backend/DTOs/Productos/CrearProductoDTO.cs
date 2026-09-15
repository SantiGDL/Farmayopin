using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Productos;

public class CrearProductoDTO
{
    [Required]
    public string Nombre { get; set; } = string.Empty;
    public string Detalle { get; set; } = string.Empty;
    public decimal Precio { get; set; }
    public string? FotoUrl { get; set; }
    public int Stock { get; set; }
}