using System.ComponentModel.DataAnnotations.Schema;

namespace farmayopin_backend.Modelos;

public class LineaDeCarrito
{
    public int Id { get; set; }
    public int CantidadProducto { get; set; }
    //Relacion con Carrito
    public int CarritoId { get; set; }
    [ForeignKey(nameof(CarritoId))]
    public Carrito CarritoAsociado { get; set; } = null!;       //Relacion muchos a 1
    //Relacion con Producto
    public int ProductoId { get; set; }
    [ForeignKey(nameof(ProductoId))]
    public Producto ProductoAsociado { get; set; } = null!;    //Tiene una referencia a 1 producto, de donde obtiene el nombre, codigo, precio y toda la magia



}