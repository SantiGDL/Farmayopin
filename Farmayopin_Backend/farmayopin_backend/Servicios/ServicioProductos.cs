using farmayopin_backend.Modelos;

namespace farmayopin_backend.Servicios;

// Datos de demostración. Más adelante este servicio consultará MariaDB.
public class ServicioProductos
{
    private readonly Producto[] productos =
    [
        new(1, "Protector solar", "Factor 50, presentación de 200 ml.", 590.00m, null, 12),
        new(2, "Crema hidratante", "Presentación de 250 ml.", 320.00m, null, 8),
        new(3, "Jabón neutro", "Presentación de 100 g.", 85.50m, null, 0)
    ];

    public IEnumerable<Producto> Listar() => productos.Select(producto => producto);

    public Producto? ObtenerPorId(int id) => productos.FirstOrDefault(producto => producto.Id == id);
}
