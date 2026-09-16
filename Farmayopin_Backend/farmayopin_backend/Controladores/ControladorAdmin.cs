using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Servicios;
using farmayopin_backend.Servicios.Resultados;
using Microsoft.AspNetCore.Mvc;

namespace farmayopin_backend.Controladores;

[ApiController]
[Route("api/controladorAdmin")]

public class ControladorAdmin : ControllerBase
{
    //Este controlador tiene todas las Funcionalidades del ADMIN:
    //<--Desde acá las llamo, luego el Servicio Admin es el que les da vida con la lógica -->
    // • Crear Producto.
    // • Ver Producto (Precio, Detalle, Foto, Stock).
    // • Editar Producto.
    // • Listar Productos.
    // • Ver Historico de Compras de un Producto (Fecha, Cantidad, Cliente).
    
    private readonly ILogger<ControladorAdmin> _logger;
    private readonly ServicioAdmin _servicioAdmin;

    public ControladorAdmin(ServicioAdmin servicio, ILogger<ControladorAdmin> logger)
    {
        this._servicioAdmin = servicio;
        this._logger = logger;
    }
    
    

    [HttpPost("crearProducto")]
    public IActionResult CrearProducto([FromBody] CrearProductoDTO nuevoProducto)
    {
        _logger.LogInformation("Llamada registrada a endpoint para crear nuevo Producto");
    
        //Ahora comparo con el ENUM del resultado, es muy práctico
        try
        {
            var resultado = _servicioAdmin.CrearProducto(nuevoProducto);

            if (resultado == ResultadoCrearProducto.Creado)
                return StatusCode(201, new { mensaje = "Producto registrado correctamente." });

            if (resultado == ResultadoCrearProducto.ProductoYaExistente)
                return Conflict(new { mensaje = "Ya existe un producto con ese código." });

            return BadRequest(new { mensaje = "Los datos del producto no son válidos." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al guardar el producto");
            return StatusCode(500, new { mensaje = "No se pudo registrar el producto." });
        }
        
    }

    [HttpPut("editarProducto")]
    public IActionResult EditarProducto([FromBody] EditarProductoDTO productoEditado)
    {
        _logger.LogInformation("Llamada registrada a endpoint para editar Producto");
        try
        {
            var resultado = _servicioAdmin.EditarProducto(productoEditado);

            if (resultado == ResultadoEditarProducto.ProductoEditado)
                return Ok(new { mensaje = "Producto editado correctamente." });

            if (resultado == ResultadoEditarProducto.ProductoNoExistente)
                return NotFound(new { mensaje = "No existe un producto con ese código." });

            return BadRequest(new { mensaje = "Los datos del producto no son válidos." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al editar el producto");
            return StatusCode(500, new { mensaje = "No se pudo editar el producto." });
        }
    }


    [HttpGet ("listarProductos")]
    public IActionResult ListarProductos()
    {
        try
        {
            List<ProductoDTO> ListaProductos = _servicioAdmin.ListarProductos();

            return Ok(ListaProductos);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al listar los productos");

            return StatusCode(500, new
            {
                mensaje = "No se pudieron obtener los productos."
            });
        }
    }


}
