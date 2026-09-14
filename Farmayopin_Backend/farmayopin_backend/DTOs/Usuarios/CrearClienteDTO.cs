using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Usuarios;

public class CrearClienteDTO
{
    //Lo utilizo para crear un cliente como indica, no le paso el parametro rol porque un usuario no define eso
    [Required]
    public string Nombre { get; set; }
    [Required, EmailAddress]
    public string Correo { get; set; }
    [Required]
    public string Pass { get; set; }
    public string Imagen { get; set; }
    
    
}