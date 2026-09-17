using System.Security.Claims;
using farmayopin_backend.DTOs.Carritos;
using farmayopin_backend.Servicios;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace farmayopin_backend.Controladores;

[ApiController]
[Route("api/controladorCliente")]
public class ControladorCliente : ControllerBase
{
    //Este controlador tiene todas las Funcionalidades del CLIENTE:
    //<--Desde acá las llamo, luego el Servicio Cliente es el que les da vida con la lógica -->
    // • Ver Productos.
    // • Agregar al Carrito.
    // • Ver Carrito.
    // • Pagar Carrito.
    // • Editar carrito (cantidades, eliminar producto)
    // • Ver historico de Compras.
    private readonly ServicioCliente _servicioCliente;
    private readonly ServicioAdmin _servicioAdmin;
    private readonly ILogger<ControladorCliente> _logger;

    public ControladorCliente(ServicioCliente servicioCliente, ServicioAdmin servicioAdmin,
        ILogger<ControladorCliente> logger)
    {
        _servicioCliente = servicioCliente;
        _servicioAdmin = servicioAdmin;
        _logger = logger;
    }

    [HttpGet("listarProductos")]
    public IActionResult ListarProductos()
    {
        try
        {
            // Reutilizamos la consulta y el DTO del listado existente.
            return Ok(_servicioAdmin.ListarProductos());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al listar productos para el cliente");
            return StatusCode(500, new { mensaje = "No se pudieron obtener los productos." });
        }
    }

    [Authorize(Roles = "Cliente")]
    [HttpGet("verCarrito")]
    public IActionResult VerCarrito()
    {
        string? identificador = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(identificador, out int usuarioId))
        {
            return Unauthorized(new { mensaje = "Volvé a iniciar sesión para ver tu carrito." });
        }

        try
        {
            CarritoDTO? carrito = _servicioCliente.VerCarrito(usuarioId);
            if (carrito == null)
            {
                return Unauthorized(new { mensaje = "La cuenta del cliente ya no está disponible." });
            }

            return Ok(carrito);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al consultar el carrito del cliente");
            return StatusCode(500, new { mensaje = "No se pudo obtener el carrito." });
        }
    }

    [Authorize(Roles = "Cliente")]
    [HttpPost("agregarProducto")]
    public IActionResult AgregarProducto([FromBody] AgregarProductoCarritoDTO datos)
    {
        return EjecutarCambio(usuarioId => _servicioCliente.AgregarProducto(usuarioId, datos));
    }

    [Authorize(Roles = "Cliente")]
    [HttpPut("lineas/{lineaId:int}")]
    public IActionResult CambiarCantidad(int lineaId, [FromBody] CambiarCantidadCarritoDTO datos)
    {
        return EjecutarCambio(usuarioId => _servicioCliente.CambiarCantidad(usuarioId, lineaId, datos.Cantidad));
    }

    [Authorize(Roles = "Cliente")]
    [HttpDelete("lineas/{lineaId:int}")]
    public IActionResult EliminarLinea(int lineaId)
    {
        return EjecutarCambio(usuarioId => _servicioCliente.EliminarLinea(usuarioId, lineaId));
    }

    [Authorize(Roles = "Cliente")]
    [HttpPost("confirmarCompra")]
    public IActionResult ConfirmarCompra()
    {
        return EjecutarCambio(usuarioId => _servicioCliente.ConfirmarCompra(usuarioId));
    }

    // Los cuatro cambios usan la misma identidad y respuestas de error.
    // Ningún DTO permite elegir un usuario o un carrito ajeno.
    private IActionResult EjecutarCambio(Func<int, object> operacion)
    {
        string? identificador = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(identificador, out int usuarioId))
        {
            return Unauthorized(new { mensaje = "Volvé a iniciar sesión." });
        }
        try
        {
            return Ok(operacion(usuarioId));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { mensaje = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { mensaje = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al modificar el carrito o confirmar la compra");
            return StatusCode(500, new { mensaje = "No se pudo completar la operación. Actualizá el carrito antes de volver a intentarlo." });
        }
    }
}
