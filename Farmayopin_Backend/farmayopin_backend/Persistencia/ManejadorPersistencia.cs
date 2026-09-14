using farmayopin_backend.Modelos;
using Microsoft.EntityFrameworkCore;

namespace farmayopin_backend.Persistencia;

public class ManejadorPersistencia : DbContext
{
    public ManejadorPersistencia(
        DbContextOptions<ManejadorPersistencia> configuracion)
        : base(configuracion)
    {
    }

    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Carrito> Carritos => Set<Carrito>();
    
    // EF Core llama a este método para configurar las entidades y sus relaciones.
    protected override void OnModelCreating(ModelBuilder modelo)
    {
        base.OnModelCreating(modelo);
        // Cada carrito pertenece a un usuario; como máximo un carrito por usuario.
        modelo.Entity<Usuario>()
            .HasOne(usuario => usuario.CarritoAsociado)
            .WithOne(carrito => carrito.UsuarioAsociado)
            .HasForeignKey<Usuario>(usuario => usuario.CarritoAsociadoId)
            .OnDelete(DeleteBehavior.Restrict);
    }
    
    
}

