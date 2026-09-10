using farmayopin_backend.Contratos;
using farmayopin_backend.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace farmayopin_backend.Controladores;

[ApiController]
[Route("api/productos")]
public class ControladorProductos(ServicioProductos servicioProductos) : ControllerBase
{
    //Esta devuelve todos los productos
    [HttpGet]
    public ActionResult<IEnumerable<ProductoDTO>> Listar() =>
        Ok(servicioProductos.Listar().Select(ProductoDTO.DesdeProducto));
    //Esta devuelve por Id
    [HttpGet("{id:int}")]
    public ActionResult<ProductoDTO> ObtenerPorId(int id)
    {
        var producto = servicioProductos.ObtenerPorId(id);
        if (producto is null)
            return Problem(statusCode: StatusCodes.Status404NotFound, title: "Producto no encontrado",
                detail: $"No existe un producto con el identificador {id}.");

        return Ok(ProductoDTO.DesdeProducto(producto));
    }
}
