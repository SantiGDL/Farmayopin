using farmayopin_backend.Servicios;

using farmayopin_backend.Persistencia;
using Microsoft.EntityFrameworkCore;

var constructor = WebApplication.CreateBuilder(args);

//Acá agrego la conección con MariaDB
constructor.Configuration.AddJsonFile(
    "Persistencia/comunicacionMariaDB.json",
    optional: false,
    reloadOnChange: false);
var conexion = constructor.Configuration.GetConnectionString("MariaDB")
               ?? throw new InvalidOperationException("Falta configurar la conexión MariaDB.");

constructor.Services.AddDbContext<ManejadorPersistencia>(configuracion =>
    configuracion.UseMySql(conexion, ServerVersion.AutoDetect(conexion)));

//Hasta acá
constructor.Services.AddControllers();
constructor.Services.AddOpenApi();
//Agrego los servicios para que los manege el gestor de dependencais como singleton
constructor.Services.AddSingleton<ServicioProductos>();
constructor.Services.AddScoped<ServicioGeneral>();
var aplicacion = constructor.Build();

if (aplicacion.Environment.IsDevelopment())
{
    aplicacion.MapOpenApi();
}
else
{
    aplicacion.UseHttpsRedirection();
}

aplicacion.UseAuthorization();
aplicacion.MapControllers();
aplicacion.Run();
