using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using farmayopin_backend.Servicios.Resultados;

namespace farmayopin_backend.Servicios;

public class ServicioAdmin
{
    //Inyecto el Manejador de Persistencia
    private readonly ManejadorPersistencia _persistencia;

    public ServicioAdmin(ManejadorPersistencia persistencia)
    {
        this._persistencia = persistencia;
    }
    
    //<----Funciones del Servicio Admin---->

    public bool BuscarProductoPorCodigo(string codigo)
    {
        var productoCodigoBuscado =
            from producto in _persistencia.Productos
            where producto.Codigo == codigo
            select producto;

        if (productoCodigoBuscado.Any())
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    public ResultadoCrearProducto CrearProducto(CrearProductoDTO nuevoProducto)
    {
        //Veo que el codigo no exista en la BD
        if (BuscarProductoPorCodigo(nuevoProducto.Codigo)) return ResultadoCrearProducto.ProductoYaExistente;   //El producto ya existe
        
        //Veo que el precio y el stock no sean negativos:
        if ((nuevoProducto.Precio < 0) || (nuevoProducto.Stock < 0)) return ResultadoCrearProducto.DatosInvalidos;
        //Si pasa los controles creo el producto y retorno true
        {
            Producto productoNuevo = new Producto(
                nuevoProducto.Codigo,
                nuevoProducto.Nombre,
                nuevoProducto.Detalle,
                nuevoProducto.Precio,
                nuevoProducto.FotoUrl,
                nuevoProducto.Stock);

            _persistencia.Productos.Add(productoNuevo);
            _persistencia.SaveChanges();

            return ResultadoCrearProducto.Creado;
        }
    }
    
    
    public ResultadoEditarProducto EditarProducto(EditarProductoDTO productoEditado)
    {
        if (productoEditado.Precio < 0 || productoEditado.Stock < 0)  return ResultadoEditarProducto.DatosInvalidos;

        var consulta =
            from producto in _persistencia.Productos
            where producto.Codigo == productoEditado.Codigo
            select producto;

        Producto? productoExistente = consulta.FirstOrDefault();

        if (productoExistente == null)  return ResultadoEditarProducto.ProductoNoExistente;

        productoExistente.Nombre = productoEditado.Nombre;
        productoExistente.Detalle = productoEditado.Detalle;
        productoExistente.Precio = productoEditado.Precio;
        productoExistente.FotoUrl = productoEditado.FotoUrl;
        productoExistente.Stock = productoEditado.Stock;

        _persistencia.SaveChanges();

        return ResultadoEditarProducto.ProductoEditado;
    }
}