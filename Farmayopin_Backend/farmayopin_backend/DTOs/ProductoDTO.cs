using farmayopin_backend.Modelos;

namespace farmayopin_backend.Contratos;

// Define el JSON público sin acoplarlo al almacenamiento del producto.
public record ProductoDTO(int Id, string Nombre, string Detalle, decimal Precio, string? FotoUrl, int Stock)
{
    public static ProductoDTO DesdeProducto(Producto producto) => new(
        producto.Id, producto.Nombre, producto.Detalle, producto.Precio, producto.FotoUrl, producto.Stock);
}
