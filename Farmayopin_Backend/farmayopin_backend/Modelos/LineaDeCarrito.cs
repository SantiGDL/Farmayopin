namespace farmayopin_backend.Modelos;

public class LineaDeCarrito
{
    public int CantidadProducto { get; set; }
    //Tiene una referencia Many to One a Carrito (O sea muchas Lineas de Carrito a un Carrito solo)
    //Tiene una referencia a 1 producto, de donde obtiene el nombre, codigo, precio y toda la magia
}