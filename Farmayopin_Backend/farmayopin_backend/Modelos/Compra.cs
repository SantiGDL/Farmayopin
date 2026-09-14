using System.Runtime.InteropServices.JavaScript;

namespace farmayopin_backend.Modelos;

public class Compra
{
    //Enum estado, no sé como con los enums
    public JSType.Date FechaCompra { get; set; }
    public float PrecioTotal { get; set; }
    //Tiene asociado 1 Cliente unico
    //Tiene asociado 1 Carrito unico perteneciente al cliente anteriormente mencionado
    //Tiene muchas lineas de compra No sé si sería así la refencia -> List<LineaDeCompra>
    //No creo, debería ser algo como un One to Many como en Java o similar
}