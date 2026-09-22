# Cómo leer el frontend

Para continuar el desarrollo, leer primero la [guía de estilo y arquitectura para nuevas sesiones](GUIA_PARA_NUEVAS_SESIONES.md).

La organización sigue los mismos grupos que el backend: General, Admin y Cliente.

```text
screens/ (dibuja y conecta eventos)
    ↓
controladores/ (coordina acciones, valida, actualiza estado y navega)
    ↓
servicios/ (ejecuta operaciones, llama al backend e interpreta JSON)
    ↓
Backend C# → Base de datos
```

## Equivalencias con tu backend

| Grupo | Pantallas actuales | Controlador | Servicio |
| --- | --- | --- | --- |
| General | Login y registro | `ControladorGeneral` | `ServicioGeneral` |
| Admin | Panel y crear producto | `ControladorAdmin` | `ServicioAdmin` |
| Cliente | Panel del cliente | `ControladorCliente` | `ServicioCliente` |

El controlador de Flutter recibe clics de botones, no solicitudes HTTP como el de C#.
Los servicios no importan Flutter ni conocen `BuildContext`, pantallas o navegación.
Las comprobaciones del frontend ayudan al usuario; el backend sigue siendo responsable de validar datos y permisos.

## Ejemplo: registrar un usuario

1. `RegisterScreen` dibuja los inputs y el botón. Sus propiedades leen el controlador.
2. El botón llama a `ControladorGeneral.registrarCliente(context)`.
3. El controlador valida el formulario y activa `enviando`.
4. `ServicioGeneral.registrarCliente` envía el POST y convierte la respuesta en `ResultadoRegistro`, el DTO específico de esta operación.
5. El controlador muestra el resultado y vuelve al login si el registro fue exitoso.

`ChangeNotifier` permite que el controlador avise de cambios mediante `notifyListeners()`.
`ListenableBuilder`, en la pantalla, escucha esos avisos y vuelve a dibujar los widgets.
La pantalla crea y libera su controlador (`dispose`). Cada formulario usa una instancia propia.
El controlador libera los campos y el cliente HTTP, y descarta respuestas si la pantalla ya se cerró.

## Qué queda en la presentación

Colores, tamaños, imágenes, disposición de columnas, campos y botones; también los
callbacks que conectan los eventos con el controlador. Un cálculo de ancho adaptable
es presentación, por eso sigue junto al diseño. `main.dart` mantiene el tema visual.
`TextEditingController` es un objeto de Flutter para leer un input; no es lo mismo
que nuestro `ControladorGeneral`, que coordina el formulario completo.

## Funciones pendientes

Esta refactorización conserva el alcance anterior:

- Registro: conectado al backend en `http://localhost:5206`.
- Login: conectado a `consultarRolUsuario`; el controlador abre el panel de Admin o Cliente según el resultado.
- Admin: abre el formulario de producto; las demás operaciones conservan sus avisos.
- Crear producto: formulario conectado mediante `ControladorCrearProducto` y `ServicioAdmin`, con foto opcional, subida multipart, creación JSON y diálogo de resultado. Ver [el recorrido completo](docs/crear_producto.md).
- Cliente: panel conectado al login; catálogo, carrito e histórico muestran avisos de función pendiente.
- Cerrar sesión desde el panel: vuelve al login; todavía no hay sesión/token.

## Verificación

Desde `farmayopin_frontend`:

```bash
flutter analyze
flutter test
```

## DTO por operación

En `lib/dtos/` cada resultado tiene su propia clase:

- `ResultadoRegistro`: éxito y mensaje del registro. Ya lo devuelve `ServicioGeneral.registrarCliente`.
- `ResultadoIniciarSesion`: éxito, mensaje y rol opcional (`Admin` o `Cliente`). Lo devuelve el servicio al iniciar sesión.

Los DTO solo transportan datos. El servicio interpreta JSON y el controlador decide cómo responder en la interfaz.

## Comunicación con el backend

Ver la [guía de comunicación frontend/backend](docs/comunicacion_frontend_backend.md), con el login explicado paso a paso y un ejemplo del registro ya conectado.
