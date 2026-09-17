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
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;
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
    private readonly SqliteConnection _conexion;

    public ConsultasClienteTests()
    {
        _conexion = new SqliteConnection("Data Source=:memory:");
        _conexion.Open();
        WebApplicationBuilder constructor = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            EnvironmentName = "Testing"
        });
        constructor.WebHost.UseTestServer();
        constructor.Logging.ClearProviders();
        IServiceCollection servicios = constructor.Services;
        servicios.AddDbContext<ManejadorPersistencia>(opciones =>
            opciones.UseSqlite(_conexion));
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
        persistencia.Database.EnsureCreated();
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

    private async Task<HttpResponseMessage> Cambiar(string correo, HttpMethod metodo, string ruta, object? datos = null)
    {
        using HttpRequestMessage solicitud = new HttpRequestMessage(metodo, "/api/controladorCliente/" + ruta);
        solicitud.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await IniciarSesion(correo));
        if (datos != null) solicitud.Content = JsonContent.Create(datos);
        return await _cliente.SendAsync(solicitud);
    }

    [Fact]
    public async Task PrimerAgregadoCreaCarritoYRepetidosSumanSinDuplicarNiDescontarStock()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia db = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        int productoId = db.Productos.Single(producto => producto.Codigo == "P1").Id;
        HttpResponseMessage primero = await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 1 });
        primero.EnsureSuccessStatusCode();
        HttpResponseMessage segundo = await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 2 });
        segundo.EnsureSuccessStatusCode();
        JsonElement carrito = await segundo.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, carrito.GetProperty("lineas").GetArrayLength());
        Assert.Equal(3, carrito.GetProperty("cantidadProductos").GetInt32());
        Assert.Equal(8050m, carrito.GetProperty("total").GetDecimal());
        Assert.Equal(3, db.Carritos.Count());
        Assert.Equal(2, db.Productos.Count());
        Assert.Equal(12, db.Productos.AsNoTracking().Single(producto => producto.Id == productoId).Stock);
    }

    [Fact]
    public async Task AgregarRechazaCantidadesInvalidasStockInsuficienteYProductoInexistente()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia db = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        int productoId = db.Productos.Single(producto => producto.Codigo == "P1").Id;
        Assert.Equal(HttpStatusCode.BadRequest, (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 0 })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 13 })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId = 999, cantidad = 1 })).StatusCode);
        Assert.Equal(2, db.Carritos.Count());
        (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 12 })).EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.Conflict, (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId, cantidad = 1 })).StatusCode);
        JsonElement carrito = await ConsultarCarrito("vacio@example.com");
        Assert.Equal(12, carrito.GetProperty("cantidadProductos").GetInt32());
    }

    [Fact]
    public async Task CantidadesYEliminarActualizanTotalesSinTocarProductosNiCarritosAjenos()
    {
        JsonElement carrito = await ConsultarCarrito("ana@example.com");
        int lineaId = carrito.GetProperty("lineas")[1].GetProperty("id").GetInt32();
        foreach (int cantidad in new[] { 3, 1 })
        {
            HttpResponseMessage cambio = await Cambiar("ana@example.com", HttpMethod.Put, "lineas/" + lineaId, new { cantidad });
            cambio.EnsureSuccessStatusCode();
            JsonElement actualizado = await cambio.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(2450m * cantidad + 301.50m + 700m, actualizado.GetProperty("total").GetDecimal());
        }
        Assert.Equal(HttpStatusCode.BadRequest, (await Cambiar("ana@example.com", HttpMethod.Put, "lineas/" + lineaId, new { cantidad = -1 })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await Cambiar("ana@example.com", HttpMethod.Put, "lineas/" + lineaId, new { cantidad = 13 })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await Cambiar("bruno@example.com", HttpMethod.Put, "lineas/" + lineaId, new { cantidad = 2 })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await Cambiar("bruno@example.com", HttpMethod.Delete, "lineas/" + lineaId)).StatusCode);
        (await Cambiar("ana@example.com", HttpMethod.Delete, "lineas/" + lineaId)).EnsureSuccessStatusCode();
        int otraLinea = carrito.GetProperty("lineas")[0].GetProperty("id").GetInt32();
        (await Cambiar("ana@example.com", HttpMethod.Delete, "lineas/" + otraLinea)).EnsureSuccessStatusCode();
        JsonElement vacio = await ConsultarCarrito("ana@example.com");
        Assert.Equal(0m, vacio.GetProperty("total").GetDecimal());
        Assert.Equal(1, (await ConsultarCarrito("bruno@example.com")).GetProperty("cantidadProductos").GetInt32());
        using IServiceScope alcance = _servidor.Services.CreateScope();
        Assert.Equal(2, alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>().Productos.Count());
    }

    [Fact]
    public async Task ConfirmacionRecalculaPreciosGuardaHistoricoDescuentaStockYVaciaElMismoCarrito()
    {
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia db = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        Producto producto = db.Productos.Single(actual => actual.Codigo == "P1");
        (await Cambiar("vacio@example.com", HttpMethod.Post, "agregarProducto", new { productoId = producto.Id, cantidad = 2 })).EnsureSuccessStatusCode();
        producto.Precio = 3000m;
        producto.Nombre = "Nombre actualizado";
        db.SaveChanges();
        JsonElement antes = await ConsultarCarrito("vacio@example.com");
        // Los importes y el usuario falsos del cuerpo no son utilizados.
        HttpResponseMessage respuesta = await Cambiar("vacio@example.com", HttpMethod.Post, "confirmarCompra", new { total = 1, usuarioId = 1 });
        respuesta.EnsureSuccessStatusCode();
        JsonElement resultado = await respuesta.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(6700m, resultado.GetProperty("total").GetDecimal());
        Compra compra = db.Compras.Include(actual => actual.ListaDeLineasCompra).Single();
        Assert.Equal(EstadoCompra.PAGADA, compra.EstadoCompra);
        Assert.Equal(db.Usuarios.Single(usuario => usuario.Correo == "vacio@example.com").Id, compra.UsuarioAsociadoId);
        Assert.Equal(antes.GetProperty("id").GetInt32(), compra.CarritoAsociadoId);
        LineaDeCompra linea = Assert.Single(compra.ListaDeLineasCompra);
        Assert.Equal("Nombre actualizado", linea.NombreProducto);
        Assert.Equal(3000m, linea.PrecioUnitario);
        Assert.Equal(2, linea.CantidadProducto);
        Assert.Equal(producto.Id, linea.ProductoAsociadoId);
        Assert.Equal(10, db.Productos.AsNoTracking().Single(actual => actual.Id == producto.Id).Stock);
        JsonElement despues = await ConsultarCarrito("vacio@example.com");
        Assert.Equal(antes.GetProperty("id").GetInt32(), despues.GetProperty("id").GetInt32());
        Assert.Equal(0, despues.GetProperty("cantidadProductos").GetInt32());
        Assert.Equal(HttpStatusCode.Conflict, (await Cambiar("vacio@example.com", HttpMethod.Post, "confirmarCompra")).StatusCode);
        Assert.Equal(1, db.Compras.Count());
        Assert.Equal(5, (await ConsultarCarrito("ana@example.com")).GetProperty("cantidadProductos").GetInt32());
    }

    [Fact]
    public async Task FaltaDeStockCancelaTodaLaCompraSinCambiosParciales()
    {
        HttpResponseMessage respuesta = await Cambiar("ana@example.com", HttpMethod.Post, "confirmarCompra");
        Assert.Equal(HttpStatusCode.Conflict, respuesta.StatusCode);
        using IServiceScope alcance = _servidor.Services.CreateScope();
        ManejadorPersistencia db = alcance.ServiceProvider.GetRequiredService<ManejadorPersistencia>();
        Assert.Empty(db.Compras);
        Assert.Empty(db.LineasDeCompra);
        Assert.Equal(12, db.Productos.Single(producto => producto.Codigo == "P1").Stock);
        Assert.Equal(3, db.LineasDeCarrito.Count());
        Assert.Equal(HttpStatusCode.Conflict, (await Cambiar("vacio@example.com", HttpMethod.Post, "confirmarCompra")).StatusCode);
    }

    [Fact]
    public async Task TodasLasMutacionesExigenSesion()
    {
        Assert.Equal(HttpStatusCode.Unauthorized, (await _cliente.PostAsJsonAsync("/api/controladorCliente/agregarProducto", new { productoId = 1, cantidad = 1 })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await _cliente.PutAsJsonAsync("/api/controladorCliente/lineas/1", new { cantidad = 1 })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await _cliente.DeleteAsync("/api/controladorCliente/lineas/1")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await _cliente.PostAsync("/api/controladorCliente/confirmarCompra", null)).StatusCode);
    }

    public void Dispose()
    {
        _cliente.Dispose();
        _aplicacion.DisposeAsync().AsTask().GetAwaiter().GetResult();
        _conexion.Dispose();
    }
}
