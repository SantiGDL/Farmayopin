using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.Modelos;

public class Producto
{
    public int Id { get; private set; }
    [Required]
    public string Nombre { get; private set; }
    public string Detalle { get; private set; }
    public float Precio { get; private set; }
    public string? FotoUrl { get; private set; }
    public int Stock { get; private set; }

    public Producto(int id, string nombre, string detalle, float precio, string? fotoUrl, int stock)
    {
        Id = id;
        Nombre = nombre;
        Detalle = detalle;
        Precio = precio;
        FotoUrl = fotoUrl;
        Stock = stock;
    }
}