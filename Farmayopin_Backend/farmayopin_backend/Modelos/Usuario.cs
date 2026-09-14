using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.Modelos;

public class Usuario
{
    public RolUsuario Rol { get; set; }
    [Required]
    public string Nombre { get; set; }
    [Required]
    public string Correo { get; set; }
    [Required]
    public string Pass { get; set; }
    public string Imagen { get; set; }

    public Usuario(string nombre, string correo, string pass, string imagen)
    {
        this.Nombre = nombre;
        this.Correo = correo;
        this.Pass = pass;
        this.Imagen = imagen;
    }
}