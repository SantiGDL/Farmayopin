# Farmayopin — Backend

Base de API REST en ASP.NET Core con C# para el laboratorio de Taller de Aplicaciones Móviles de UTEC.

## Qué está implementado

- Se reemplazó el ejemplo WeatherForecast por un catálogo de productos.
- Tres productos de demostración almacenados en memoria.
- Listado de productos y consulta por identificador.
- Respuesta 404 cuando el producto no existe.
- Código organizado en español, con modelo, contrato, servicio y controlador.
- Documento OpenAPI disponible durante desarrollo.

Todavía no hay base de datos, autenticación, roles, creación/edición de productos, carrito ni compras. Los endpoints son públicos y los datos se reinicializan en cada arranque. Las fotos de ejemplo tienen `fotoUrl: null`. Los precios usan `decimal`.

## Estructura

```text
farmayopin_backend/
  Controladores/ControladorProductos.cs  Recibe las solicitudes HTTP
  Modelos/Producto.cs                   Representa un producto
  DTOs/ProductoDTO.cs        Define los datos de respuesta
  Servicios/ServicioProductos.cs        Consulta los productos en memoria
  Program.cs                           Configura la aplicación y sus servicios
  farmayopin_backend.http              Solicitudes de ejemplo
```

`DTOs` contiene los DTO: objetos que definen los datos que la API envía al cliente. Esto permite cambiar el almacenamiento sin cambiar necesariamente la respuesta pública.

El recorrido de una consulta es: solicitud HTTP → controlador → servicio → productos en memoria → contrato de respuesta → JSON.

## Ejecutar

Requisito: SDK .NET 10.

Desde la raíz del repositorio, donde está `farmayopin_backend.sln`:

```bash
dotnet restore farmayopin_backend.sln
dotnet build farmayopin_backend.sln
dotnet run --project farmayopin_backend --launch-profile http
```

Si la terminal está dentro de la carpeta del proyecto, donde está este README, alcanza con:

```bash
dotnet run --launch-profile http
```

La API queda disponible en `http://localhost:5206`. Mantengan la terminal abierta mientras la usan. En desarrollo se permite HTTP local; fuera de desarrollo se habilita la redirección a HTTPS. No hay una política CORS configurada actualmente.

## Probar los endpoints

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/api/productos` | Lista de productos |
| GET | `/api/productos/1` | Producto con ID 1 |
| GET | `/api/productos/999` | Error 404 |

Pueden abrir las direcciones en el navegador, usar el archivo `farmayopin_backend.http` desde Rider o ejecutar:

```bash
curl http://localhost:5206/api/productos
curl http://localhost:5206/api/productos/1
curl -i http://localhost:5206/api/productos/999
```

Ejemplo de respuesta para el producto 1:

```json
{
  "id": 1,
  "nombre": "Protector solar",
  "detalle": "Factor 50, presentación de 200 ml.",
  "precio": 590.00,
  "fotoUrl": null,
  "stock": 12
}
```

El documento OpenAPI está en `http://localhost:5206/openapi/v1.json` durante desarrollo. No se agregó una interfaz Swagger UI.

## Cómo continuar

1. Conectar MariaDB y reemplazar los datos en memoria por persistencia.
2. Agregar creación y edición de productos con validaciones.
3. Implementar registro, login y permisos por rol. El registro público debe crear clientes.
4. Implementar carrito, compra e historiales.

Los precios y el stock se deben validar en el servidor. Al implementar compras, guardar el nombre y precio del producto en el detalle de compra para conservar el historial, y registrar la compra junto con el descuento de stock en una transacción.

## Verificación

La base inicial se compiló sin errores ni advertencias y se comprobaron por HTTP el listado, el detalle, el error 404 y el documento OpenAPI. Tras retirar la configuración del cliente, se volvió a compilar el backend.
