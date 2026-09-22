using System.ComponentModel.DataAnnotations;
using farmayopin_backend.Modelos;

namespace farmayopin_backend.DTOs.Productos;

public class CrearProductoDTO
{
    [Required]
    public string Codigo { get; set; } = string.Empty;
    [Required]
    public string Nombre { get; set; } = string.Empty;
    public string Detalle { get; set; } = string.Empty;
    [Range(typeof(decimal), "0", "79228162514264337593543950335")]
    public decimal Precio { get; set; }
    public string? FotoUrl { get; set; }
    [Range(0, int.MaxValue)]
    public int Stock { get; set; }
    [EnumDataType(typeof(CategoriaProducto))]
    public CategoriaProducto? Categoria { get; set; }
    [EnumDataType(typeof(UnidadMedida))]
    public UnidadMedida? Unidad { get; set; }
}