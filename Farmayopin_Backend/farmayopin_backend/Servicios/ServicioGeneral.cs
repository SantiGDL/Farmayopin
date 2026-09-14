using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Modelos;

namespace farmayopin_backend.Servicios;

public class ServicioGeneral
{
    //Tengo que hacer una comunicacion con mariadb

    public void CrearCliente(CrearClienteDTO nuevoCliente)
    {
        Usuario nuevoUsuario = new Usuario(nuevoCliente.Nombre, nuevoCliente.Correo, nuevoCliente.Pass, nuevoCliente.Imagen);
        nuevoUsuario.Rol = RolUsuario.Cliente;
        //TODO -> Hashear la contraseña antes de guardarla
        
    }
}