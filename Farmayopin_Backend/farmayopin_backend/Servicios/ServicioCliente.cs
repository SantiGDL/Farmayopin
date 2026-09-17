using farmayopin_backend.DTOs.Carritos;
using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Data;

namespace farmayopin_backend.Servicios;

public class ServicioCliente
{
    private readonly ManejadorPersistencia _persistencia;
    private const decimal CostoEnvio = 700m;

    public ServicioCliente(ManejadorPersistencia persistencia)
    {
        _persistencia = persistencia;
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

        carrito.Envio = CostoEnvio;
        carrito.Total = carrito.Subtotal + CostoEnvio;

        return carrito;
    }

    public CarritoDTO AgregarProducto(int usuarioId, AgregarProductoCarritoDTO datos)
    {
        using IDbContextTransaction transaccion = _persistencia.Database.BeginTransaction(IsolationLevel.Serializable);
        Usuario cliente = ObtenerClienteParaModificar(usuarioId);
        Producto producto = ObtenerProductoParaModificar(datos.ProductoId);
        ValidarCantidad(datos.Cantidad, producto.Stock);

        if (cliente.CarritoAsociadoId == null)
        {
            cliente.CarritoAsociado = new Carrito();
            _persistencia.SaveChanges();
        }

        int carritoId = cliente.CarritoAsociadoId!.Value;
        LineaDeCarrito? linea = _persistencia.LineasDeCarrito.SingleOrDefault(
            actual => actual.CarritoId == carritoId && actual.ProductoId == producto.Id);

        if (linea == null)
        {
            linea = new LineaDeCarrito
            {
                CarritoId = carritoId,
                ProductoId = producto.Id,
                CantidadProducto = datos.Cantidad
            };
            _persistencia.LineasDeCarrito.Add(linea);
        }
        else
        {
            long nuevaCantidad = (long)linea.CantidadProducto + datos.Cantidad;
            ValidarCantidad(nuevaCantidad, producto.Stock);
            linea.CantidadProducto = (int)nuevaCantidad;
        }

        // Agregar no reserva ni descuenta stock; eso ocurre al confirmar.
        _persistencia.SaveChanges();
        transaccion.Commit();
        return VerCarrito(usuarioId)!;
    }

    public CarritoDTO CambiarCantidad(int usuarioId, int lineaId, int cantidad)
    {
        using IDbContextTransaction transaccion = _persistencia.Database.BeginTransaction(IsolationLevel.Serializable);
        Usuario cliente = ObtenerClienteParaModificar(usuarioId);
        LineaDeCarrito linea = ObtenerLineaPropia(cliente, lineaId);
        Producto producto = ObtenerProductoParaModificar(linea.ProductoId);
        ValidarCantidad(cantidad, producto.Stock);
        linea.CantidadProducto = cantidad;
        _persistencia.SaveChanges();
        transaccion.Commit();
        return VerCarrito(usuarioId)!;
    }

    public CarritoDTO EliminarLinea(int usuarioId, int lineaId)
    {
        using IDbContextTransaction transaccion = _persistencia.Database.BeginTransaction(IsolationLevel.Serializable);
        Usuario cliente = ObtenerClienteParaModificar(usuarioId);
        LineaDeCarrito linea = ObtenerLineaPropia(cliente, lineaId);
        _persistencia.LineasDeCarrito.Remove(linea);
        _persistencia.SaveChanges();
        transaccion.Commit();
        return VerCarrito(usuarioId)!;
    }

    public CompraConfirmadaDTO ConfirmarCompra(int usuarioId)
    {
        using IDbContextTransaction transaccion = _persistencia.Database.BeginTransaction(IsolationLevel.Serializable);
        Usuario cliente = ObtenerClienteParaModificar(usuarioId);
        if (cliente.CarritoAsociadoId == null)
        {
            throw new InvalidOperationException("Tu carrito está vacío.");
        }

        // Bloqueamos productos en orden para que dos compras concurrentes no
        // descuenten el mismo stock ni creen una compra con datos parciales.
        List<LineaDeCarrito> lineas = _persistencia.LineasDeCarrito
            .Where(linea => linea.CarritoId == cliente.CarritoAsociadoId)
            .OrderBy(linea => linea.ProductoId)
            .ToList();
        if (lineas.Count == 0)
        {
            throw new InvalidOperationException("Tu carrito está vacío.");
        }

        Compra compra = new Compra
        {
            UsuarioAsociadoId = cliente.Id,
            CarritoAsociadoId = cliente.CarritoAsociadoId.Value,
            FechaCompra = DateTime.UtcNow,
            EstadoCompra = EstadoCompra.PAGADA
        };
        decimal subtotal = 0;
        foreach (LineaDeCarrito linea in lineas)
        {
            Producto producto = ObtenerProductoParaModificar(linea.ProductoId);
            ValidarCantidad(linea.CantidadProducto, producto.Stock);
            LineaDeCompra detalle = new LineaDeCompra(
                linea.CantidadProducto, producto.Precio, producto.Nombre)
            {
                ProductoAsociadoId = producto.Id
            };
            compra.ListaDeLineasCompra.Add(detalle);
            subtotal += producto.Precio * linea.CantidadProducto;
            producto.Stock -= linea.CantidadProducto;
        }

        compra.PrecioTotal = subtotal + CostoEnvio;
        _persistencia.Compras.Add(compra);
        _persistencia.LineasDeCarrito.RemoveRange(lineas);
        _persistencia.SaveChanges();
        transaccion.Commit();

        return new CompraConfirmadaDTO
        {
            CompraId = compra.Id,
            Subtotal = subtotal,
            Envio = CostoEnvio,
            Total = compra.PrecioTotal
        };
    }

    private Usuario ObtenerClienteParaModificar(int usuarioId)
    {
        Usuario? cliente;
        if (_persistencia.Database.IsMySql())
        {
            // El bloqueo del usuario serializa también la creación de su primer
            // carrito y evita líneas duplicadas al recibir dos solicitudes juntas.
            cliente = _persistencia.Usuarios
                .FromSqlInterpolated($"SELECT * FROM Usuarios WHERE Id = {usuarioId} FOR UPDATE")
                .AsEnumerable().SingleOrDefault();
        }
        else
        {
            cliente = _persistencia.Usuarios.SingleOrDefault(usuario => usuario.Id == usuarioId);
        }
        if (cliente == null || cliente.Rol != RolUsuario.Cliente)
        {
            throw new UnauthorizedAccessException("Volvé a iniciar sesión con una cuenta de cliente.");
        }
        return cliente;
    }

    private Producto ObtenerProductoParaModificar(int productoId)
    {
        Producto? producto;
        if (_persistencia.Database.IsMySql())
        {
            producto = _persistencia.Productos
                .FromSqlInterpolated($"SELECT * FROM Productos WHERE Id = {productoId} FOR UPDATE")
                .AsEnumerable().SingleOrDefault();
        }
        else
        {
            producto = _persistencia.Productos.SingleOrDefault(actual => actual.Id == productoId);
        }
        if (producto == null)
        {
            throw new KeyNotFoundException("El producto ya no está disponible.");
        }
        return producto;
    }

    private LineaDeCarrito ObtenerLineaPropia(Usuario cliente, int lineaId)
    {
        LineaDeCarrito? linea = _persistencia.LineasDeCarrito.SingleOrDefault(
            actual => actual.Id == lineaId && actual.CarritoId == cliente.CarritoAsociadoId);
        if (linea == null)
        {
            throw new KeyNotFoundException("No se encontró ese producto en tu carrito.");
        }
        return linea;
    }

    private static void ValidarCantidad(long cantidad, int stock)
    {
        if (cantidad < 1)
        {
            throw new InvalidOperationException("La cantidad mínima es 1.");
        }
        if (cantidad > stock)
        {
            throw new InvalidOperationException("No hay stock suficiente. Actualizá el carrito y revisá las cantidades.");
        }
    }
}
