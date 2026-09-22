using farmayopin_backend.DTOs.Compras;
using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using farmayopin_backend.Servicios.Resultados;
using Microsoft.EntityFrameworkCore;

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

    //<--Buscar Producto-->
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
    //<--Crear Producto-->
    public ResultadoCrearProducto CrearProducto(CrearProductoDTO nuevoProducto)
    {
        if (string.IsNullOrWhiteSpace(nuevoProducto.Codigo) ||
            string.IsNullOrWhiteSpace(nuevoProducto.Nombre))
            return ResultadoCrearProducto.DatosInvalidos;
        if (nuevoProducto.Categoria.HasValue && !Enum.IsDefined(nuevoProducto.Categoria.Value))
            return ResultadoCrearProducto.DatosInvalidos;
        if (nuevoProducto.Unidad.HasValue && !Enum.IsDefined(nuevoProducto.Unidad.Value))
            return ResultadoCrearProducto.DatosInvalidos;

        nuevoProducto.Codigo = nuevoProducto.Codigo.Trim();
        nuevoProducto.Nombre = nuevoProducto.Nombre.Trim();
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

            productoNuevo.Categoria = nuevoProducto.Categoria;
            productoNuevo.Unidad = nuevoProducto.Unidad;
            _persistencia.Productos.Add(productoNuevo);
            _persistencia.SaveChanges();

            return ResultadoCrearProducto.Creado;
        }
    }
    
    // La imagen llega como archivo multipart; en la BD solo se guardará su ruta.
    public async Task<string> SubirFoto(IFormFile foto, string carpetaWeb, CancellationToken cancelacion)
    {
        const int maximoBytes = 5 * 1024 * 1024;
        if (foto.Length == 0 || foto.Length > maximoBytes)
            throw new ArgumentException("La foto debe pesar entre 1 byte y 5 MB.");

        // No confiamos en la extensión o el nombre enviado por el dispositivo.
        // Comprobamos la firma del archivo y generamos nuestro propio nombre.
        using Stream origen = foto.OpenReadStream();
        byte[] cabecera = new byte[8];
        int leidos = await origen.ReadAtLeastAsync(cabecera, 8, false, cancelacion);
        bool esPng = leidos == 8 && cabecera.AsSpan().SequenceEqual(
            new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
        bool esJpg = leidos >= 3 && cabecera[0] == 255 && cabecera[1] == 216 && cabecera[2] == 255;
        if (!esPng && !esJpg)
            throw new ArgumentException("Seleccioná una imagen JPG o PNG.");

        string extension = esPng ? ".png" : ".jpg";
        string nombre = Guid.NewGuid().ToString("N") + extension;
        string carpeta = Path.Combine(carpetaWeb, "Imagenes", "Productos");
        Directory.CreateDirectory(carpeta);
        string rutaArchivo = Path.Combine(carpeta, nombre);
        // CreateNew impide sobrescribir un archivo incluso ante una colisión.
        await using FileStream destino = new FileStream(rutaArchivo, FileMode.CreateNew);
        try
        {
            await destino.WriteAsync(cabecera.AsMemory(0, leidos), cancelacion);
            await origen.CopyToAsync(destino, cancelacion);
        }
        catch
        {
            await destino.DisposeAsync();
            File.Delete(rutaArchivo);
            throw;
        }
        return "/Imagenes/Productos/" + nombre;
    }

    //<--Editar Producto-->
    public ResultadoEditarProducto EditarProducto(EditarProductoDTO productoEditado)
    {
        if (productoEditado.Categoria.HasValue && !Enum.IsDefined(productoEditado.Categoria.Value))
            return ResultadoEditarProducto.DatosInvalidos;

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
        productoExistente.Categoria = productoEditado.Categoria;

        _persistencia.SaveChanges();

        return ResultadoEditarProducto.ProductoEditado;
    }


    // <--Listar Productos-->
    public List<ProductoDTO> ListarProductos()
    {
        var productos = _persistencia.Productos
            .AsNoTracking()
            .OrderBy(producto => producto.Nombre)
            .ToList();

        List<ProductoDTO> listaProductosDTO = new List<ProductoDTO>();

        foreach (var producto in productos)
        {
            ProductoDTO productoDTO = new ProductoDTO(
                producto.Id,
                producto.Codigo,
                producto.Nombre,
                producto.Detalle,
                producto.Precio,
                producto.FotoUrl,
                producto.Stock,
                producto.Categoria?.ToString(),
                producto.Unidad?.ToString()
            );

            listaProductosDTO.Add(productoDTO);
        }

        return listaProductosDTO;
    }



    // La relación usa la PK del producto, nunca su código de negocio.
    public List<CompraProductoDTO>? HistoricoProducto(int productoId)
    {
        if (!_persistencia.Productos.Any(producto => producto.Id == productoId))
            return null;

        return _persistencia.LineasDeCompra
            .AsNoTracking()
            .Where(linea => linea.ProductoAsociadoId == productoId)
            .OrderByDescending(linea => linea.CompraAsociada.FechaCompra)
            .ThenByDescending(linea => linea.Id)
            .Select(linea => new CompraProductoDTO
            {
                FechaCompra = DateTime.SpecifyKind(linea.CompraAsociada.FechaCompra, DateTimeKind.Utc),
                CantidadProducto = linea.CantidadProducto,
                PrecioUnitario = linea.PrecioUnitario,
                NombreCliente = linea.CompraAsociada.UsuarioAsociado.Nombre,
                CorreoCliente = linea.CompraAsociada.UsuarioAsociado.Correo
            })
            .ToList();
    }
}
