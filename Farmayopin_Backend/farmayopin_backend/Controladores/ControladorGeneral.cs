using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Modelos;
using farmayopin_backend.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace farmayopin_backend.Controladores;

[ApiController]
[Route("api/controladorGeneral")]
public class ControladorGeneral : ControllerBase
{
    //Este controlador maneja las funcionalidades compartidas o generales del sistema como:
    //<--Desde acá las llamo, luego el Servicio General es el que les da vida con la lógica -->
    // • Crear Usuario (Cliente)
    // • Login
    // • Logout.
    
    //<--Extras-->
    
    // • Crear Usuario (Admin) -> Solo usable por programador (TODO -> ver si se deja o no)

    
    private readonly ServicioGeneral _servicioGeneral;
    private readonly ILogger<ControladorGeneral> _logger;   //Es para loguear mensajes

    // Inyecto el servicio y el logger en el constructor
    public ControladorGeneral(ServicioGeneral servicio, ILogger<ControladorGeneral> logger)
    {
        _servicioGeneral = servicio;
        _logger = logger;
    }
    
    [HttpPost("nuevoCliente")]
    public IActionResult CrearCliente([FromBody] CrearClienteDTO nuevoCliente)
    {
        _logger.LogInformation("Llamada registrada a endpoint para crear nuevo cliente");
        _servicioGeneral.CrearCliente(nuevoCliente);
        return Ok();
    }
    
}