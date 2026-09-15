using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Modelos;
using farmayopin_backend.Servicios;
using farmayopin_backend.Servicios.Resultados;
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

    [HttpPost("consultarRolUsuario")]
    public IActionResult ConsultarRolUsuario([FromBody] ConsultaRolDTO usuarioConsultado)
    {
        //Consulto Rol a BD
        var resultado = _servicioGeneral.ConsultarRolUsuario(usuarioConsultado);
        
        if (resultado == ResultadoConsultarRolUsuario.RolCliente)
        {
            return Ok(new { rol = "Cliente" });     //Envio JSON con Rol Cliente 
        }
        else if (resultado == ResultadoConsultarRolUsuario.RolAdmin)
        {
            return Ok(new { rol = "Admin" });       //Envio JSON con Rol Admin  
        }
        else if (resultado == ResultadoConsultarRolUsuario.NoExisteUsuario ||
                 resultado == ResultadoConsultarRolUsuario.PassNoCoincide)
        {
            return Unauthorized(new { mensaje = "Correo o contraseña incorrectos." });
        }
        else
        {
            return StatusCode(500, new { mensaje = "Rol de usuario no reconocido." });
        }
    }
   
    
    
    
    
    [HttpPost("nuevoCliente")]
    public IActionResult CrearCliente([FromBody] CrearClienteDTO nuevoCliente)
    {
        _logger.LogInformation("Llamada registrada a endpoint para crear nuevo cliente");

        if (!ModelState.IsValid)
        {
            return BadRequest(new { mensaje = "Los datos del cliente no son válidos." });
        }

        try
        {
            _servicioGeneral.CrearCliente(nuevoCliente);
            return Ok(new { mensaje = "Usuario registrado correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { mensaje = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al crear un nuevo cliente");
            return StatusCode(500, new { mensaje = "No se pudo registrar el usuario." });
        }
    }
    
}