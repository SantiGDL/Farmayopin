# Crear producto y subir una foto

## Recorrido del código

1. `CrearProductoScreen` dibuja los campos y conecta los eventos.
2. `ControladorCrearProducto` mantiene los campos, valida y coordina las dos peticiones. Es el controlador del formulario administrativo; `ControladorAdmin` conserva la navegación del panel y las consultas del listado.
3. `ServicioAdmin.subirFoto` envía los bytes mediante `multipart/form-data` a `POST /api/controladorAdmin/subirFoto`, en el campo `foto`.
4. El controlador C# recibe `IFormFile`; `ServicioAdmin.SubirFoto` comprueba tamaño y firma JPG/PNG, genera un nombre GUID y escribe en `wwwroot/Imagenes/Productos`. Responde HTTP 201 con `{"fotoUrl":"/Imagenes/Productos/<nombre>.png"}`.
5. `ServicioAdmin.crearProducto` envía JSON al endpoint existente, con código, nombre, detalle, precio, stock, categoría y `fotoUrl`. Si no se seleccionó imagen, omite la subida y envía `fotoUrl: null`.
6. Si recibe HTTP 201, el controlador muestra `AlertaDialog` y vuelve al menú cuando el usuario acepta. Ante un error, conserva el formulario para corregirlo o reintentar.

Los valores de categoría corresponden al enum C#: 0 = analgésicos, 1 = higiene, 2 = primeros auxilios. Se agregó el campo Código porque es obligatorio en el backend. La unidad sigue siendo opcional en el endpoint; el formulario actual no la solicita.

`FotoProductoSelector` muestra la selección, vista previa y botón para quitarla. Se usa `file_selector`, mantenido por Flutter, con selección de un archivo JPG/PNG de hasta 5 MiB. No se implementa arrastrar archivos ni tomar fotos con la cámara. `AlertaDialog` utiliza Flutter, sin SweetAlert2 ni npm.

## Conexión desde un celular Android

El backend debe estar accesible desde el teléfono. En desarrollo, conectar teléfono y PC a la misma red, iniciar el backend escuchando en la red local y configurar la app con la IP de la PC:

```bash
# Desde Farmayopin_Backend/farmayopin_backend
 dotnet run --urls http://0.0.0.0:5206

# Desde farmayopin_frontend (reemplazar por la IP real de la PC)
 flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5206
```

Permitir el puerto 5206 en el firewall local si está bloqueado. En el emulador Android se puede usar `http://10.0.2.2:5206`. `localhost` en un teléfono apunta al propio teléfono.

La app Android tiene permiso de internet. Solo las variantes debug/profile permiten HTTP sin cifrar; para release usar un backend HTTPS. En web, una página HTTPS también debe consultar un backend HTTPS. El selector de archivos no requiere permisos amplios para acceder a todo el almacenamiento. Se añadieron los permisos de selección de archivos y conexión saliente para macOS.

Al agregar el plugin, detener y volver a ejecutar la app: hot reload no incorpora la parte nativa de una dependencia nueva.

## Errores y límites

- Subida fallida: no se intenta crear el producto.
- Código repetido: se muestra el mensaje HTTP 409 del backend; se pueden corregir los campos.
- Creación fallida después de subir: se conserva la URL en el controlador para no repetir la subida al reintentar.
- Mientras hay una operación, se bloquean las acciones del formulario y la navegación hacia atrás para evitar envíos dobles.
- Si se pierde la respuesta de creación, el producto podría haberse guardado: el mensaje pide revisar el listado antes de reintentar.
- Si se abandona el formulario después de una subida exitosa, se reemplaza esa foto o se pierde la respuesta de subida, puede quedar un archivo sin producto asociado. No hay limpieza automática de esos archivos; este flujo de dos peticiones no es una transacción única.
- El backend comprueba la firma de los archivos, pero no los recodifica ni comprueba toda su integridad. Una imagen dañada puede no mostrar vista previa.

No se agregan tablas ni migraciones. Las rutas administrativas conservan su esquema actual de acceso; este cambio no incorpora autenticación administrativa.

## Verificación

`flutter analyze` y `flutter test`. En backend: `dotnet test Farmayopin_Backend/farmayopin_backend.Tests/farmayopin_backend.Tests.csproj` desde la raíz del repositorio.

Las pruebas del backend usan SQLite y una carpeta temporal aislada: comprueban subida multipart, descarga HTTP del archivo, ruta almacenada, categorías, datos inválidos y códigos repetidos. No escriben en MariaDB ni en la carpeta real de productos. Las pruebas Flutter simulan el selector y las respuestas HTTP; la selección nativa en un teléfono necesita una comprobación manual.
