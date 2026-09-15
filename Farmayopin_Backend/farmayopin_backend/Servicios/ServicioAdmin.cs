using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;

namespace farmayopin_backend.Servicios;

public class ServicioAdmin
{
    //Inyecto el Manejador de Persistencia
    private readonly ManejadorPersistencia _persistencia;

    public ServicioAdmin(ManejadorPersistencia persistencia)
    {
        this._persistencia = persistencia;
    }
    
    //Funciones del Servicio Admin:
    public bool CrearProducto(CrearProductoDTO nuevoProducto)
    {
        //Válido los datos que me llegan
        //Veo que el precio y el stock no sean negativos:
        if ((nuevoProducto.Precio < 0) || (nuevoProducto.Stock < 0)) return false;

        else
        {

            //int id, string nombre, string detalle, decimal precio, string? fotoUrl, int stock)

            Producto productoNuevo = new Producto(
                nuevoProducto.Nombre,
                nuevoProducto.Detalle,
                nuevoProducto.Precio,
                nuevoProducto.FotoUrl,
                nuevoProducto.Stock);

            _persistencia.Productos.Add(productoNuevo);
            _persistencia.SaveChanges();

            return true;
        }
    }
}