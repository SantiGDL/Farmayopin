using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;
using farmayopin_backend.Controladores;
using farmayopin_backend.Modelos;
using farmayopin_backend.Persistencia;
using farmayopin_backend.Servicios;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace farmayopin_backend.Tests;

// Se prueban las rutas y controladores reales con una BD aislada en memoria.
// Ninguna prueba se conecta ni modifica la MariaDB del proyecto.
public class ConsultasClienteTests : IDisposable
{
    private readonly TestServer _servidor;
    private readonly WebApplication _aplicacion;
    private readonly HttpClient _cliente;

    public ConsultasClienteTests()
    {
        string basePrueba = Guid.NewGuid().ToString();
        WebApplicationBuilder constructor = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            EnvironmentName = "Testing"
        });
        constructor.WebHost.UseTestServer();
        constructor.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Carrito:CostoEnvio"] = "700"
        });
        IServiceCollection servicios = constructor.Services;
        servicios.AddDbContext<ManejadorPersistencia>(opciones =>
            opciones.UseInMemoryDatabase(basePrueba));
        servicios.AddControllers().AddApplicationPart(typeof(ControladorCliente).Assembly);
        servicios.AddSingleton<IDataProtectionProvider>(new EphemeralDataProtectionProvider());
        servicios.AddAuthentication(BearerTokenDefaults.AuthenticationScheme).AddBearerToken();
        servicios.AddAuthorization();
        servicios.AddScoped<ServicioGeneral>();
        servicios.AddScoped<ServicioAdmin>();
        servicios.AddScoped<ServicioCliente>();
        servicios.AddScoped<ServicioSesionCliente>();
        _aplicacion = constructor.Build();
        _aplicacion.UseRouting();
        _aplicacion.UseAuthentication();
        _aplicacion.UseAuthorization();
        _aplicacion.MapControllers();
        _aplicacion.StartAsync().GetAwaiter().GetResult();
        _servidor = _aplicacion.GetTestServer();
        _cliente = _servidor.CreateClient();
        PrepararDatos();
    }

    private void PrepararDatos()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia persistencia = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        Producto medicamento = new Producto("P1", "Paracetamol", "Analgésico", 2450m, "/Imagenes/Productos/Paracetamol.jpeg", 12)
        {
            Categoria = CategoriaProducto.ANALGESICOS,
            Unidad = UnidadMedida.TABLETA
        };
        Producto higiene = new Producto("P2", "Jabón", "Higiene personal", 100.50m, null, 0)
        {
            Categoria = CategoriaProducto.HIGIENE
        };
        Usuario ana = new Usuario("Ana", "ana@example.com", "prueba123", "")
        {
            Rol = RolUsuario.Cliente,
            CarritoAsociado = new Carrito()
        };
        Usuario bruno = new Usuario("Bruno", "bruno@example.com", "prueba123", "")
        {
            Rol = RolUsuario.Cliente,
            CarritoAsociado = new Carrito()
        };
        persistencia.AddRange(medicamento, higiene, ana, bruno,
            new Usuario("Sin carrito", "vacio@example.com", "prueba123", "") { Rol = RolUsuario.Cliente },
            new Usuario("Admin", "admin@example.com", "prueba123", "") { Rol = RolUsuario.Admin });
        persistencia.SaveChanges();
        persistencia.LineasDeCarrito.AddRange(
            new LineaDeCarrito { CarritoId = ana.CarritoAsociadoId!.Value, ProductoId = medicamento.Id, CantidadProducto = 2 },
            new LineaDeCarrito { CarritoId = ana.CarritoAsociadoId.Value, ProductoId = higiene.Id, CantidadProducto = 3 },
            new LineaDeCarrito { CarritoId = bruno.CarritoAsociadoId!.Value, ProductoId = higiene.Id, CantidadProducto = 1 });
        persistencia.SaveChanges();
    }

    private async Task<string> IniciarSesion(string correo)
    {
        HttpResponseMessage respuesta = await _cliente.PostAsJsonAsync(
            "/api/controladorGeneral/consultarRolUsuario", new { Correo = correo, Pass = "prueba123" });
        respuesta.EnsureSuccessStatusCode();
        JsonElement datos = await respuesta.Content.ReadFromJsonAsync<JsonElement>();
        return datos.GetProperty("token").GetString()!;
    }

    private async Task<JsonElement> ConsultarCarrito(string correo, string ruta = "/api/controladorCliente/verCarrito")
    {
        string token = await IniciarSesion(correo);
        using HttpRequestMessage solicitud = new HttpRequestMessage(HttpMethod.Get, ruta);
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        HttpResponseMessage respuesta = await _cliente.SendAsync(solicitud);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<JsonElement>();
    }

    [Fact]
    public async Task ListadoReutilizaContratoAdministrativoEIncluyeCategorias()
    {
        JsonElement productos = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorCliente/listarProductos");
        JsonElement administrativos = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorAdmin/listarProductos");
        Assert.Equal(administrativos.GetRawText(), productos.GetRawText());
        Assert.Equal(2, productos.GetArrayLength());
        Assert.Equal("Jabón", productos[0].GetProperty("nombre").GetString());
        Assert.Equal("ANALGESICOS", productos[1].GetProperty("categoria").GetString());
        Assert.Equal("TABLETA", productos[1].GetProperty("unidad").GetString());
    }

    [Fact]
    public async Task ListadoVacioDevuelveUnaListaVacia()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia persistencia = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        persistencia.LineasDeCarrito.RemoveRange(persistencia.LineasDeCarrito);
        persistencia.Productos.RemoveRange(persistencia.Productos);
        persistencia.SaveChanges();
        JsonElement productos = await _cliente.GetFromJsonAsync<JsonElement>("/api/controladorCliente/listarProductos");
        Assert.Equal(0, productos.GetArrayLength());
    }

    [Fact]
    public async Task CarritoCalculaCantidadesPreciosYEnvioSinDescontarStock()
    {
        JsonElement carrito = await ConsultarCarrito("ana@example.com");
        Assert.Equal(5, carrito.GetProperty("cantidadProductos").GetInt32());
        Assert.Equal(5201.50m, carrito.GetProperty("subtotal").GetDecimal());
        Assert.Equal(700m, carrito.GetProperty("envio").GetDecimal());
        Assert.Equal(5901.50m, carrito.GetProperty("total").GetDecimal());
        JsonElement lineas = carrito.GetProperty("lineas");
        Assert.Equal(301.50m, lineas[0].GetProperty("subtotal").GetDecimal());
        Assert.Equal(0, lineas[0].GetProperty("producto").GetProperty("stock").GetInt32());
        Assert.Equal(12, lineas[1].GetProperty("producto").GetProperty("stock").GetInt32());
    }

    [Fact]
    public async Task CadaTokenConsultaSoloSuCarritoAunqueSeEnvieOtroUsuario()
    {
        JsonElement ana = await ConsultarCarrito("ana@example.com", "/api/controladorCliente/verCarrito?usuarioId=2");
        JsonElement bruno = await ConsultarCarrito("bruno@example.com");
        Assert.Equal(5, ana.GetProperty("cantidadProductos").GetInt32());
        Assert.Equal(1, bruno.GetProperty("cantidadProductos").GetInt32());
        Assert.NotEqual(ana.GetProperty("id").GetInt32(), bruno.GetProperty("id").GetInt32());
    }

    [Fact]
    public async Task ClienteSinCarritoRecibeVacioSinCrearRegistros()
    {
        JsonElement carrito = await ConsultarCarrito("vacio@example.com");
        Assert.Equal(JsonValueKind.Null, carrito.GetProperty("id").ValueKind);
        Assert.Equal(0, carrito.GetProperty("lineas").GetArrayLength());
        Assert.Equal(0m, carrito.GetProperty("total").GetDecimal());
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia persistencia = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        Assert.Equal(2, persistencia.Carritos.Count());
    }

    [Fact]
    public async Task CarritoAsociadoSinLineasNoCobraEnvio()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia persistencia = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        persistencia.LineasDeCarrito.RemoveRange(persistencia.LineasDeCarrito);
        persistencia.SaveChanges();
        JsonElement carrito = await ConsultarCarrito("ana@example.com");
        Assert.Equal(0, carrito.GetProperty("lineas").GetArrayLength());
        Assert.Equal(0m, carrito.GetProperty("envio").GetDecimal());
        Assert.Equal(0m, carrito.GetProperty("total").GetDecimal());
    }

    [Fact]
    public async Task TarifaNoDefinidaNoInventaEnvioNiTotal()
    {
        IConfiguration configuracion = _servidor.Services.GetRequiredService<IConfiguration>();
        configuracion["Carrito:CostoEnvio"] = null;
        JsonElement carrito = await ConsultarCarrito("ana@example.com");
        Assert.Equal(JsonValueKind.Null, carrito.GetProperty("envio").ValueKind);
        Assert.Equal(JsonValueKind.Null, carrito.GetProperty("total").ValueKind);
        Assert.Equal(5201.50m, carrito.GetProperty("subtotal").GetDecimal());
    }

    [Fact]
    public async Task CarritoRechazaSolicitudSinTokenOTokenAlterado()
    {
        HttpResponseMessage anonima = await _cliente.GetAsync("/api/controladorCliente/verCarrito");
        Assert.Equal(HttpStatusCode.Unauthorized, anonima.StatusCode);
        using HttpRequestMessage alterada = new HttpRequestMessage(HttpMethod.Get, "/api/controladorCliente/verCarrito");
        alterada.Headers.Authorization = new AuthenticationHeaderValue("Bearer", "token-alterado");
        HttpResponseMessage respuesta = await _cliente.SendAsync(alterada);
        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task CarritoRechazaTokenVencido()
    {
        BearerTokenOptions opciones = _servidor.Services.GetRequiredService<IOptionsMonitor<BearerTokenOptions>>()
            .Get(BearerTokenDefaults.AuthenticationScheme);
        ClaimsIdentity identidad = new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "1"), new Claim(ClaimTypes.Role, "Cliente")
        }, BearerTokenDefaults.AuthenticationScheme);
        AuthenticationTicket ticket = new AuthenticationTicket(new ClaimsPrincipal(identidad),
            new AuthenticationProperties { ExpiresUtc = DateTimeOffset.UtcNow.AddMinutes(-1) },
            BearerTokenDefaults.AuthenticationScheme);
        string token = opciones.BearerTokenProtector.Protect(ticket);
        using HttpRequestMessage solicitud = new HttpRequestMessage(HttpMethod.Get, "/api/controladorCliente/verCarrito");
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        HttpResponseMessage respuesta = await _cliente.SendAsync(solicitud);
        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task LoginConservaRespuestaDeAdminYRechazaCredencialesIncorrectas()
    {
        HttpResponseMessage admin = await _cliente.PostAsJsonAsync("/api/controladorGeneral/consultarRolUsuario",
            new { Correo = "admin@example.com", Pass = "prueba123" });
        JsonElement datos = await admin.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Admin", datos.GetProperty("rol").GetString());
        Assert.False(datos.TryGetProperty("token", out _));
        HttpResponseMessage incorrecta = await _cliente.PostAsJsonAsync("/api/controladorGeneral/consultarRolUsuario",
            new { Correo = "ana@example.com", Pass = "incorrecta" });
        Assert.Equal(HttpStatusCode.Unauthorized, incorrecta.StatusCode);
    }

    public void Dispose()
    {
        _cliente.Dispose();
        _aplicacion.DisposeAsync().AsTask().GetAwaiter().GetResult();
    }
}
