using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.Modelos;

public class Usuario
{
    public int Id { get; set; } //la cedula de toda la vida
    public RolUsuario Rol { get; set; }
    [Required]
    public string Nombre { get; set; }
    [Required, EmailAddress]
    public string Correo { get; set; }
    [Required]
    public string Pass { get; set; }
    public string Imagen { get; set; }
    //Relacion con Carrito (1 a 1) -> Permito que sea null al comienzo, por los Admin
    public int? CarritoAsociadoId { get; set; }
    public Carrito? CarritoAsociado { get; set; }
    //Relacion con Compra (1 a muchas)
    public List<Compra> Compras { get; set; } = new();
    
    
    
    
    public Usuario(string nombre, string correo, string pass, string imagen)
    {
        this.Nombre = nombre;
        this.Correo = correo;
        this.Pass = pass;
        this.Imagen = imagen;
    }
}
