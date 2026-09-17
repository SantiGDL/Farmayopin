using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.DTOs.Productos;
// Define el JSON público sin acoplarlo al almacenamiento del producto.
public class ProductoDTO
{
    public int Id { get; set; }
    [Required]
    public string Codigo { get; set; }
    [Required]
    public string Nombre { get; set; }
    public string Detalle { get; set; }
    public decimal Precio { get; set; }
    public string? FotoUrl { get; set; }
    public int Stock { get; set; }
    public string? Categoria { get; set; }
    public string? Unidad { get; set; }

    public ProductoDTO(int id, string codigo, string nombre, string detalle, decimal precio, string? fotoUrl, int stock,
        string? categoria = null, string? unidad = null)
    {
        this.Id = id;
        this.Codigo = codigo;
        this.Nombre = nombre;
        this.Detalle = detalle;
        this.Precio = precio;
        this.FotoUrl = fotoUrl;
        this.Stock = stock;
        this.Categoria = categoria;
        this.Unidad = unidad;
    }

}
