using farmayopin_backend.DTOs.Carritos;
using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using Microsoft.EntityFrameworkCore;

namespace farmayopin_backend.Servicios;

public class ServicioCliente
{
    private readonly ManejadorPersistencia _persistencia;
    private readonly IConfiguration _configuracion;

    public ServicioCliente(ManejadorPersistencia persistencia, IConfiguration configuracion)
    {
        _persistencia = persistencia;
        _configuracion = configuracion;
    }

    public CarritoDTO? VerCarrito(int usuarioId)
    {
        Usuario? cliente = _persistencia.Usuarios
            .AsNoTracking()
            .SingleOrDefault(usuario => usuario.Id == usuarioId && usuario.Rol == RolUsuario.Cliente);

        if (cliente == null)
        {
            return null;
        }

        CarritoDTO carrito = new CarritoDTO();
        carrito.Id = cliente.CarritoAsociadoId;

        // Registrarse todavía no crea un carrito. Consultarlo no escribe en la BD.
        if (cliente.CarritoAsociadoId != null)
        {
            List<LineaDeCarrito> lineas = _persistencia.LineasDeCarrito
                .AsNoTracking()
                .Include(linea => linea.ProductoAsociado)
                .Where(linea => linea.CarritoId == cliente.CarritoAsociadoId)
                .OrderBy(linea => linea.ProductoAsociado.Nombre)
                .ToList();

            foreach (LineaDeCarrito linea in lineas)
            {
                Producto producto = linea.ProductoAsociado;
                ProductoDTO productoDTO = new ProductoDTO(
                    producto.Id, producto.Codigo, producto.Nombre, producto.Detalle,
                    producto.Precio, producto.FotoUrl, producto.Stock,
                    producto.Categoria?.ToString(), producto.Unidad?.ToString());
                LineaDeCarritoDTO lineaDTO = new LineaDeCarritoDTO(
                    linea.Id, productoDTO, linea.CantidadProducto);

                carrito.Lineas.Add(lineaDTO);
                carrito.CantidadProductos += lineaDTO.Cantidad;
                carrito.Subtotal += lineaDTO.Subtotal;
            }
        }

        if (carrito.Lineas.Count == 0)
        {
            carrito.Envio = 0;
            carrito.Total = 0;
            return carrito;
        }

        decimal? costoEnvio = _configuracion.GetValue<decimal?>("Carrito:CostoEnvio");
        if (costoEnvio.HasValue && costoEnvio.Value >= 0)
        {
            carrito.Envio = costoEnvio.Value;
            carrito.Total = carrito.Subtotal + costoEnvio.Value;
        }

        return carrito;
    }
}
