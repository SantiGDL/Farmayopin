using System.ComponentModel.DataAnnotations;

namespace farmayopin_backend.Modelos;

//Un "Producto Comprado" es una copia de un Producto, lo utilizo para no tener una referencia a Producto que puede luego cambiar
public class LineaDeCompra
{
    public int CantidadProducto { get; set; }
    public float PrecioUnitario { get; set; }
    [Required]
    public string NombreProducto { get; set; }
    //Tiene una referencia a Producto
    //Tiene una referencia a la Compra que lo creó

    public LineaDeCompra(int cantidadProducto, float precioUnitario, string nombreProducto)
    {
        this.CantidadProducto = cantidadProducto;
        this.PrecioUnitario = precioUnitario;
        this.NombreProducto = nombreProducto;
    }
}