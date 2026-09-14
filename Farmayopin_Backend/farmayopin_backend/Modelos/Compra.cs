namespace farmayopin_backend.Modelos;

public class Compra
{
    public int Id { get; set; }
    public EstadoCompra EstadoCompra { get; set; }
    public DateTime FechaCompra { get; set; }
    public decimal PrecioTotal { get; set; }
    //Relacion Usuario (muchos a 1)
    public int UsuarioAsociadoId { get; set; }
    public Usuario UsuarioAsociado { get; set; } = null!;
    //Relacion con Carrito (muchas compras a 1)
    public int CarritoAsociadoId { get; set; }
    public Carrito CarritoAsociado { get; set; } = null!;
    //Relacion con Líneas de Compra (1 a muchas)
    public List<LineaDeCompra> ListaDeLineasCompra { get; set; } = new();
}
