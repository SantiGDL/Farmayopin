using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using farmayopin_backend.Servicios.Resultados;

namespace farmayopin_backend.Servicios;

public class ServicioGeneral
{
    //Inyecto el Manejador de Persistencia
    private readonly ManejadorPersistencia _persistencia;

    public ServicioGeneral(ManejadorPersistencia persistencia)
    {
        this._persistencia = persistencia;
    }
    
    //Funciones del Servicio General:
    public Usuario CrearCliente(CrearClienteDTO nuevoCliente)
    {
        var nombre = nuevoCliente.Nombre.Trim();
        var correo = nuevoCliente.Correo.Trim();
        var password = nuevoCliente.Pass;

        if (string.IsNullOrWhiteSpace(nombre))
            throw new InvalidOperationException("El nombre no puede estar vacío.");

        if (string.IsNullOrWhiteSpace(correo))
            throw new InvalidOperationException("El correo no puede estar vacío.");

        if (string.IsNullOrWhiteSpace(password))
            throw new InvalidOperationException("La contraseña no puede estar vacía.");

        var correoExistente = _persistencia.Usuarios
            .Any(usuario => usuario.Correo.ToLower() == correo.ToLower());

        if (correoExistente)
            throw new InvalidOperationException("Ya existe un usuario registrado con ese correo.");

        Usuario nuevoUsuario = new Usuario(nombre, correo, password, nuevoCliente.Imagen ?? string.Empty);
        nuevoUsuario.Rol = RolUsuario.Cliente;
        //TODO -> Hashear la contraseña antes de guardarla

        _persistencia.Usuarios.Add(nuevoUsuario);
        _persistencia.SaveChanges();
        return nuevoUsuario;
    }



    public ResultadoConsultarRolUsuario ConsultarRolUsuario(ConsultaRolDTO usuarioConsultado)
    {
        return ConsultarRolUsuario(usuarioConsultado, out _);
    }

    // La sobrecarga conserva el contrato anterior y permite identificar al cliente
    // autenticado sin consultar dos veces sus credenciales.
    public ResultadoConsultarRolUsuario ConsultarRolUsuario(ConsultaRolDTO usuarioConsultado, out int? usuarioId)
    {
        usuarioId = null;
        //Obtengo el Usuario
        var consulta =
            from usuario in _persistencia.Usuarios
            where usuario.Correo == usuarioConsultado.Correo
            select usuario;

        Usuario? usuarioExistente = consulta.SingleOrDefault();
        //Validaciones
        if (usuarioExistente == null) return ResultadoConsultarRolUsuario.NoExisteUsuario;
        
        if (usuarioExistente.Pass != usuarioConsultado.Pass) return ResultadoConsultarRolUsuario.PassNoCoincide;
        usuarioId = usuarioExistente.Id;
        
        if (usuarioExistente.Rol == RolUsuario.Admin) return ResultadoConsultarRolUsuario.RolAdmin;
        
        if (usuarioExistente.Rol == RolUsuario.Cliente)  return ResultadoConsultarRolUsuario.RolCliente;
        else{ //Es redundante, pero me ayuda a ser feliz
            throw new InvalidOperationException("Rol de usuario no reconocido.");
        }
        
        
        
    }
    
}
