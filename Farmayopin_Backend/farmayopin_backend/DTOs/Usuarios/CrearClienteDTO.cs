using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Usuarios;

public class CrearClienteDTO
{
    //Lo utilizo para crear un cliente como indica, no le paso el parametro rol porque un usuario no define eso
    [Required]
    public string Nombre { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Correo { get; set; } = string.Empty;

    [Required]
    public string Pass { get; set; } = string.Empty;

    public string Imagen { get; set; } = string.Empty;
}