using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using farmayopin_backend.Controladores;
using farmayopin_backend.Persistencia;
using farmayopin_backend.Servicios;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;

namespace farmayopin_backend.Tests;

// HTTP real contra los controladores, con SQLite y archivos temporales aislados.
public class CrearProductoTests : IDisposable
{
    private readonly string _carpeta = Path.Combine(Path.GetTempPath(), "farmayopin-fotos-" + Guid.NewGuid());
    private readonly SqliteConnection _conexion = new SqliteConnection("Data Source=:memory:");
    private readonly WebApplication _app;
    private readonly HttpClient _cliente;
    private static readonly byte[] Png = Convert.FromBase64String(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=");

    public CrearProductoTests()
    {
        Directory.CreateDirectory(_carpeta);
        _conexion.Open();
        WebApplicationBuilder builder = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            EnvironmentName = "Testing", WebRootPath = _carpeta
        });
        builder.WebHost.UseTestServer();
        builder.Logging.ClearProviders();
        builder.Services.AddDbContext<ManejadorPersistencia>(opciones => opciones.UseSqlite(_conexion));
        builder.Services.AddScoped<ServicioAdmin>();
        builder.Services.AddControllers().AddApplicationPart(typeof(ControladorAdmin).Assembly);
        _app = builder.Build();
        _app.UseStaticFiles();
        _app.MapControllers();
        using (IServiceScope scope = _app.Services.CreateScope())
        {
            scope.ServiceProvider.GetRequiredService<ManejadorPersistencia>().Database.EnsureCreated();
        }
        _app.StartAsync().GetAwaiter().GetResult();
        _cliente = _app.GetTestClient();
    }

    [Fact]
    public async Task EditarUsaCodigoYGuardaCategoriaSinCrearOtroProducto()
    {
        (await Crear("SKU-EDITAR", "/Imagenes/Productos/original.png")).EnsureSuccessStatusCode();
        JsonElement antes = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        HttpResponseMessage respuesta = await _cliente.PutAsJsonAsync("/api/controladorAdmin/editarProducto", new
        {
            codigo = "SKU-EDITAR", nombre = "Nombre editado", detalle = "Detalle nuevo",
            precio = 250.75m, stock = 15, categoria = 2, fotoUrl = "/Imagenes/Productos/original.png"
        });
        respuesta.EnsureSuccessStatusCode();
        JsonElement despues = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal(1, despues.GetArrayLength());
        Assert.Equal(antes[0].GetProperty("id").GetInt32(), despues[0].GetProperty("id").GetInt32());
        Assert.Equal("SKU-EDITAR", despues[0].GetProperty("codigo").GetString());
        Assert.Equal("Nombre editado", despues[0].GetProperty("nombre").GetString());
        Assert.Equal("Detalle nuevo", despues[0].GetProperty("detalle").GetString());
        Assert.Equal(250.75m, despues[0].GetProperty("precio").GetDecimal());
        Assert.Equal(15, despues[0].GetProperty("stock").GetInt32());
        Assert.Equal("PRIMEROS_AUXILIOS", despues[0].GetProperty("categoria").GetString());
        Assert.Equal("TABLETA", despues[0].GetProperty("unidad").GetString());
        Assert.Equal("/Imagenes/Productos/original.png", despues[0].GetProperty("fotoUrl").GetString());
    }

    [Fact]
    public async Task EditarRechazaCategoriaInvalidaSinModificarElProducto()
    {
        (await Crear("SKU-EDITAR")).EnsureSuccessStatusCode();
        HttpResponseMessage respuesta = await _cliente.PutAsJsonAsync("/api/controladorAdmin/editarProducto", new
        {
            codigo = "SKU-EDITAR", nombre = "No guardar", precio = 1, stock = 1, categoria = 999
        });
        Assert.Equal(HttpStatusCode.BadRequest, respuesta.StatusCode);
        JsonElement lista = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal("Jabón", lista[0].GetProperty("nombre").GetString());
        Assert.Equal("HIGIENE", lista[0].GetProperty("categoria").GetString());
    }

    private Task<HttpResponseMessage> Crear(string codigo, string? fotoUrl = null, int categoria = 1,
        decimal precio = 12.50m, int stock = 3, string nombre = "Jabón")
    {
        return _cliente.PostAsJsonAsync("/api/controladorAdmin/crearProducto", new
        {
            codigo, nombre, detalle = "Descripción", precio, stock, categoria, unidad = 0, fotoUrl
        });
    }

    private async Task<HttpResponseMessage> Subir(byte[] datos, string nombre)
    {
        using MultipartFormDataContent cuerpo = new MultipartFormDataContent();
        cuerpo.Add(new ByteArrayContent(datos), "foto", nombre);
        return await _cliente.PostAsync("/api/controladorAdmin/subirFoto", cuerpo);
    }

    [Theory]
    [InlineData(0, "MEDICAMENTOS")]
    [InlineData(1, "HIGIENE")]
    [InlineData(3, "VITAMINAS")]
    [InlineData(4, "SIN_CATEGORIA")]
    public async Task GuardaCadaCategoriaEnLaBaseDeDatos(int categoria, string nombre)
    {
        Assert.Equal(HttpStatusCode.Created, (await Crear("CATEGORIA", categoria: categoria)).StatusCode);
        using var consulta = _conexion.CreateCommand();
        consulta.CommandText = "SELECT Categoria FROM Productos WHERE Codigo = 'CATEGORIA'";
        Assert.Equal(categoria, Convert.ToInt32(await consulta.ExecuteScalarAsync()));
        JsonElement lista = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal(nombre, lista[0].GetProperty("categoria").GetString());
        JsonElement catalogo = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/categorias");
        Assert.Equal(4, catalogo.GetArrayLength());
        var opcion = catalogo.EnumerateArray().Single(c => c.GetProperty("id").GetInt32() == categoria);
        Assert.Equal(opcion.GetProperty("nombre").GetString(), lista[0].GetProperty("categoriaNombre").GetString());
    }

    [Fact]
    public async Task CreaSinFotoYGuardaCategoriaUnidadYDecimales()
    {
        Assert.Equal(HttpStatusCode.Created, (await Crear("NUEVO")).StatusCode);
        JsonElement lista = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal("NUEVO", lista[0].GetProperty("codigo").GetString());
        Assert.Equal("HIGIENE", lista[0].GetProperty("categoria").GetString());
        Assert.Equal("TABLETA", lista[0].GetProperty("unidad").GetString());
        Assert.Equal(12.50m, lista[0].GetProperty("precio").GetDecimal());
        Assert.Equal(JsonValueKind.Null, lista[0].GetProperty("fotoUrl").ValueKind);
    }

    [Fact]
    public async Task SubeArchivoLoSirvePorHttpYGuardaLaRutaRelativa()
    {
        HttpResponseMessage subida = await Subir(Png, "../../foto.png");
        Assert.Equal(HttpStatusCode.Created, subida.StatusCode);
        JsonElement resultado = await subida.Content.ReadFromJsonAsync<JsonElement>();
        string ruta = resultado.GetProperty("fotoUrl").GetString()!;
        Assert.Matches(@"^/Imagenes/Productos/[a-f0-9]{32}\.png$", ruta);
        Assert.Equal(Png, await _cliente.GetByteArrayAsync(ruta));
        Assert.Equal(HttpStatusCode.Created, (await Crear("CON-FOTO", ruta)).StatusCode);
        JsonElement lista = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal(ruta, lista[0].GetProperty("fotoUrl").GetString());
        HttpResponseMessage segunda = await Subir(Png, "../../foto.png");
        JsonElement otro = await segunda.Content.ReadFromJsonAsync<JsonElement>();
        Assert.NotEqual(ruta, otro.GetProperty("fotoUrl").GetString());
    }

    [Fact]
    public async Task RechazaCodigoRepetidoYNoDuplicaElProducto()
    {
        await Crear("MISMO");
        Assert.Equal(HttpStatusCode.Conflict, (await Crear(" MISMO ")).StatusCode);
        JsonElement lista = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal(1, lista.GetArrayLength());
    }

    [Fact]
    public async Task RechazaDatosInvalidos()
    {
        Assert.Equal(HttpStatusCode.BadRequest, (await Crear(" ")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Crear("P", nombre: " ")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Crear("P", precio: -1)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Crear("P", stock: -1)).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Crear("P", categoria: 99)).StatusCode);
    }

    [Fact]
    public async Task RechazaArchivosVaciosFalsosYMayoresA5Mb()
    {
        Assert.Equal(HttpStatusCode.BadRequest, (await Subir([], "vacio.jpg")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Subir("no es una foto"u8.ToArray(), "falso.png")).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await Subir(new byte[5 * 1024 * 1024 + 1], "grande.png")).StatusCode);
        Assert.Empty(Directory.GetFiles(_carpeta, "*", SearchOption.AllDirectories));
    }

    public void Dispose()
    {
        _cliente.Dispose();
        _app.DisposeAsync().AsTask().GetAwaiter().GetResult();
        _conexion.Dispose();
        Directory.Delete(_carpeta, true);
    }
}
