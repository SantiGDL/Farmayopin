using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Carritos;

public class AgregarProductoCarritoDTO
{
    [Range(1, int.MaxValue)]
    public int ProductoId { get; set; }

    [Range(1, int.MaxValue)]
    public int Cantidad { get; set; }
}
