using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.Modelos;

public class Producto
{
    public int Id { get; private set; }
    [Required]
    public string Nombre { get; set; }
    public string Detalle { get; set; }
    public decimal Precio { get; set; }
    public string? FotoUrl { get; set; }
    public int Stock { get; set; }
   

    public Producto(string nombre, string detalle, decimal precio, string? fotoUrl, int stock)
    {
        Nombre = nombre;
        Detalle = detalle;
        Precio = precio;
        FotoUrl = fotoUrl;
        Stock = stock;
    }
}