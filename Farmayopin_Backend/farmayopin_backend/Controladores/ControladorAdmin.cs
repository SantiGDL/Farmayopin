using farmayopin_backend.DTOs.Productos;
using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Servicios;
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

        try
        {
            if (_servicioAdmin.CrearProducto(nuevoProducto))
            {
                return StatusCode(201, new { mensaje = "Producto registrado correctamente." });
            }

            return BadRequest(new { mensaje = "Los datos del Producto no son válidos." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al guardar el Producto en la BD");
            return StatusCode(500, new { mensaje = "Error al guardar el Producto en la BD" });
        }
        
    }
}