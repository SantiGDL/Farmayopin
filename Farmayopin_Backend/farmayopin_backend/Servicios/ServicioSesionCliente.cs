using System.Globalization;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.Extensions.Options;

namespace farmayopin_backend.Servicios;

// Usa los tokens protegidos de ASP.NET Core para consultar el carrito propio.
// No contiene contraseñas ni acepta un usuario elegido por el frontend.
public class ServicioSesionCliente
{
    private readonly IOptionsMonitor<BearerTokenOptions> _opciones;

    public ServicioSesionCliente(IOptionsMonitor<BearerTokenOptions> opciones)
    {
        _opciones = opciones;
    }

    public string CrearToken(int usuarioId)
    {
        string esquema = BearerTokenDefaults.AuthenticationScheme;
        BearerTokenOptions opciones = _opciones.Get(esquema);
        List<Claim> datos = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, usuarioId.ToString(CultureInfo.InvariantCulture)),
            new Claim(ClaimTypes.Role, "Cliente")
        };
        ClaimsIdentity identidad = new ClaimsIdentity(datos, esquema);
        ClaimsPrincipal cliente = new ClaimsPrincipal(identidad);
        AuthenticationProperties propiedades = new AuthenticationProperties
        {
            ExpiresUtc = DateTimeOffset.UtcNow.Add(opciones.BearerTokenExpiration)
        };
        AuthenticationTicket comprobante = new AuthenticationTicket(cliente, propiedades, esquema);
        return opciones.BearerTokenProtector.Protect(comprobante);
    }
}
