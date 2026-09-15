using System.ComponentModel.DataAnnotations;
using farmayopin_backend.Modelos;

namespace farmayopin_backend.DTOs.Productos;

public class EditarProductoDTO
{
    [Required]
    public string Codigo { get; set; }
    [Required]
    public string Nombre { get; set; } = string.Empty;
    public string Detalle { get; set; } = string.Empty;
    public decimal Precio { get; set; }
    public string? FotoUrl { get; set; }
    public int Stock { get; set; }
    public CategoriaProducto? Categoria { get; set; }
    public UnidadMedida? Unidad { get; set; }

}