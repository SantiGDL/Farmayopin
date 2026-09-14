using farmayopin_backend.DTOs.Usuarios;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;

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
    public void CrearCliente(CrearClienteDTO nuevoCliente)
    {
        Usuario nuevoUsuario = new Usuario(nuevoCliente.Nombre, nuevoCliente.Correo, nuevoCliente.Pass, nuevoCliente.Imagen);
        nuevoUsuario.Rol = RolUsuario.Cliente;
        //TODO -> Hashear la contraseña antes de guardarla

        _persistencia.Usuarios.Add(nuevoUsuario);
        _persistencia.SaveChanges();
    }
}