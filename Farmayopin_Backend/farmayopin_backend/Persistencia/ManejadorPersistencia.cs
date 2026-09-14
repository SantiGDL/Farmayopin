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
    
    
    public DbSet<Carrito> Carritos => Set<Carrito>();
    public DbSet<Compra> Compras => Set<Compra>();
    public DbSet<LineaDeCarrito> LineasDeCarrito => Set<LineaDeCarrito>();
    public DbSet<LineaDeCompra> LineasDeCompra => Set<LineaDeCompra>();
    public DbSet<Producto> Productos => Set<Producto>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    
    // EF Core llama a este método para configurar las entidades y sus relaciones.
    protected override void OnModelCreating(ModelBuilder modelo) 
    {
        base.OnModelCreating(modelo); // Ejecuta la configuración de la clase base DbContext.
        
        modelo.Entity<Usuario>() // Comienza la configuración de la entidad Usuario.
            .HasOne(usuario => usuario.CarritoAsociado) // Un usuario puede tener un carrito asociado.
            .WithOne(carrito => carrito.UsuarioAsociado) // Ese carrito puede estar asociado a un único usuario: relación uno a uno.
            .HasForeignKey<Usuario>(usuario => usuario.CarritoAsociadoId) // Usuario guarda la clave foránea que apunta al Id del carrito.
            .OnDelete(DeleteBehavior.Restrict); // Impide borrar un carrito mientras un usuario lo tenga referenciado.
        //Hago que el correo del usuario sea unico
        modelo.Entity<Usuario>()
            .HasIndex(usuario => usuario.Correo)
            .IsUnique();
        
        modelo.Entity<LineaDeCompra>() 
            .HasOne(linea => linea.ProductoAsociado) 
            .WithMany() 
            .HasForeignKey(linea => linea.ProductoAsociadoId) 
            .OnDelete(DeleteBehavior.Restrict); 
        
        
        
    }
    
}

