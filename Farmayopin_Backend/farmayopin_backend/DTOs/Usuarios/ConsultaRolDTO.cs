using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Usuarios;

public class ConsultaRolDTO
{
    //Este DTO se usa para que el Usuario envie sus credenciales y yo le retorne su ROL
    [Required, EmailAddress]
    public string Correo { get; set; } = string.Empty;
    [Required]
    public string Pass { get; set; } = string.Empty;
}