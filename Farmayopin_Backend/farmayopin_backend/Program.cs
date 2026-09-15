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

constructor.Services.AddCors(opciones =>
{
    opciones.AddPolicy("FlutterDev", politica =>
    {
        politica
            .SetIsOriginAllowed(_ => true)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

//Hasta acá
constructor.Services.AddControllers();
constructor.Services.AddOpenApi();
//Agrego los servicios para que los manege el gestor de depedencias como singleton
//Es para que el backend pueda crear el servicio de productos como dependencia injectable en otras partes del sistema.
//Osea que cuando otra clase lo necesite, el sistema le va a dar la misma instancia de ServicioProductos que se creó acá.
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

aplicacion.UseCors("FlutterDev");
aplicacion.UseAuthorization();
aplicacion.MapControllers();
aplicacion.Run();
