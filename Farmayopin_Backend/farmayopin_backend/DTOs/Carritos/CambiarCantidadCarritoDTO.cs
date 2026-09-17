using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Carritos;

public class CambiarCantidadCarritoDTO
{
    [Range(1, int.MaxValue)]
    public int Cantidad { get; set; }
}
