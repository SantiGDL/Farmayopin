using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Productos;
// Define el JSON público sin acoplarlo al almacenamiento del producto.
public class ProductoDTO
{
    public int Id { get; private set; }
    [Required]
    public string Nombre { get; private set; }
    public string Detalle { get; private set; }
    public decimal Precio { get; private set; }
    public string? FotoUrl { get; private set; }
    public int Stock { get; private set; }

    public ProductoDTO(int id, string nombre, string detalle, decimal precio, string? fotoUrl, int stock)
    {
        this.Id = id;
        this.Nombre = nombre;
        this.Detalle = detalle;
        this.Precio = precio;
        this.FotoUrl = fotoUrl;
        this.Stock = stock;
    }

}
