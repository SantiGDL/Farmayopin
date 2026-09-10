using farmayopin_backend.Servicios;

var constructor = WebApplication.CreateBuilder(args);

constructor.Services.AddControllers();
constructor.Services.AddOpenApi();
constructor.Services.AddSingleton<ServicioProductos>();

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
