using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace farmayopin_backend.Modelos;

//Un "Producto Comprado" es una copia de un Producto, lo utilizo para no tener una referencia a Producto que puede luego cambiar
public class LineaDeCompra
{
    public int Id { get; set; }
    public int CantidadProducto { get; set; }
    public decimal PrecioUnitario { get; set; }
    [Required]
    public string NombreProducto { get; set; }
    //Tiene una referencia a Producto
    //Relacion con Producto (Muchos a 1)
    public int ProductoAsociadoId { get; set; }
    public Producto ProductoAsociado { get; set; } = null!;
    //Tiene una referencia a la Compra que lo creó (muchas a 1)
    public int CompraAsociadaId { get; set; }
    public Compra CompraAsociada { get; set; } = null!;
    

    public LineaDeCompra(int cantidadProducto, decimal precioUnitario, string nombreProducto)
    {
        this.CantidadProducto = cantidadProducto;
        this.PrecioUnitario = precioUnitario;
        this.NombreProducto = nombreProducto;
    }
}