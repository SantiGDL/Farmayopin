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
}
