namespace farmayopin_backend.Modelos;

public class Carrito
{
    public int Id { get; set; }
    //Relacion con Usuario
    public Usuario UsuarioAsociado { get; set; } = null!;      
    //Relacion con LineaDeCarrito (1 a muchas)
    public List<LineaDeCarrito> ListaDeLineasCarrito { get; set; } = new();     
    //Relacion con Compra (1 a muchas -> luego cada compra tiene su lista de lineas (Sería el detalle de la compra)
    public List<Compra> ListaDeCompras { get; set; } = new();   
    
    
    
    public Carrito(){}
    
}