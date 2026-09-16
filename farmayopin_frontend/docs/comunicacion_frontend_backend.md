# Cómo se comunican el frontend y el backend de Farmayopin

Esta guía explica nuestra organización por **General, Admin y Cliente**, y el recorrido de una operación desde que el usuario toca un botón hasta que recibe una respuesta.

## 1. La idea principal

**La pantalla dibuja, el controlador coordina, el servicio del frontend llama a la API y el backend ejecuta las operaciones sobre los datos.**

```text
FRONTEND · Flutter / Dart

Pantalla → Controlador → Servicio
                           │
                       HTTP + JSON
                           │
BACKEND · C#               ▼

                     Controlador → Servicio → Persistencia / Base de datos
```

La respuesta vuelve por el camino inverso. El frontend no accede directamente a la base de datos.

## 2. Responsabilidades de cada parte

| Parte | Responsabilidad | Ejemplo en el login |
| --- | --- | --- |
| Pantalla de Flutter | Dibujar los componentes y conectar sus eventos con el controlador. | Mostrar correo, contraseña y botón «Ingresar». |
| Controlador de Flutter | Validar el formulario, coordinar acciones, manejar estado, mensajes y navegación. | Pedir la consulta del rol y decidir qué pantalla abrir. |
| Servicio de Dart | Enviar HTTP, interpretar códigos y JSON, y devolver un DTO. | Enviar las credenciales y transformar la respuesta en `ResultadoConsultarRol`. |
| Controlador de C# | Recibir la solicitud HTTP y producir una respuesta HTTP. | Recibir `ConsultaRolDTO` y responder con el rol o un error. |
| Servicio de C# | Aplicar las reglas de negocio y consultar o modificar los datos mediante la persistencia. | Comprobar las credenciales y obtener el rol guardado. |

Aunque compartan nombres, un controlador de Flutter y uno de C# reciben cosas diferentes: el primero recibe **eventos de la interfaz**, mientras que el segundo recibe **solicitudes HTTP**.

### ¿Quién decide qué hacer?

Ambos, controlador y servicio del frontend, toman decisiones, pero de distinto tipo:

- **Servicio:** «Recibí HTTP 401; devuelvo un resultado fallido».
- **Controlador:** «La operación falló; muestro el mensaje al usuario».
- **Pantalla:** «El controlador indica que está enviando; dibujo un indicador de carga».

El servicio Dart no usa `Navigator`, `BuildContext` ni `SnackBar`. Tampoco comprueba por su cuenta si una contraseña coincide con la base de datos: solicita esa comprobación al backend.

## 3. Nuestra organización por grupos

| Grupo | Funciones | Archivos del frontend |
| --- | --- | --- |
| General | Registro, inicio de sesión y acciones compartidas. | `controlador_general.dart`, `servicio_general.dart` |
| Admin | Panel y operaciones administrativas de productos. | `controlador_admin.dart`, `servicio_admin.dart` |
| Cliente | Futuras funciones del cliente. | `controlador_cliente.dart`, `servicio_cliente.dart` |

Las pantallas están en `lib/screens/`, los controladores en `lib/controladores/`, los servicios en `lib/servicios/` y los DTO en `lib/dtos/`.

Esta agrupación sigue la forma de pensar del backend. No requiere un servicio por cada pantalla: login y registro usan el grupo General. Cada formulario crea su propia instancia del controlador para no compartir los valores de sus campos.

## 4. Ejemplo concreto: iniciar sesión y consultar el rol

> **Estado actual:** el endpoint del backend y el DTO `ResultadoConsultarRol` existen. La consulta desde Flutter todavía está pendiente: el login actual valida el formulario y muestra un aviso. El recorrido que sigue describe cómo se conectará, no una funcionalidad ya terminada.

### Paso 1: el usuario completa la pantalla

`LoginScreen` muestra los campos de correo y contraseña. El usuario escribe y toca «Ingresar».

El botón llama a `ControladorGeneral.iniciarSesion(context)`. Los valores de los inputs están disponibles a través de los `TextEditingController` que guarda ese controlador.

Un `TextEditingController` es un objeto de Flutter que permite leer un campo de texto; no es lo mismo que nuestro `ControladorGeneral`, que coordina el formulario completo.

### Paso 2: el controlador valida y llama al servicio

El controlador verifica que el formulario sea válido: por ejemplo, que haya un correo con formato correcto y una contraseña no vacía.

Esta validación ayuda al usuario a completar el formulario. **No demuestra que las credenciales sean correctas.** Esa decisión corresponde al backend.

Si el formulario es válido, el controlador deberá activar el estado de carga y llamar a un método como:

```dart
// Ejemplo del paso pendiente de implementar.
final resultado = await servicio.consultarRol(correo, password);
```

`await` espera el resultado sin bloquear la interfaz. En Dart, `Future<ResultadoConsultarRol>` es parecido a `Task<ResultadoConsultarRol>` en C#.

### Paso 3: el servicio envía las credenciales al backend

El servicio del frontend realizará un POST al endpoint existente:

```text
http://localhost:5206/api/controladorGeneral/consultarRolUsuario
```

Con el encabezado `Content-Type: application/json` y un cuerpo como este, con datos ficticios:

```json
{
  "Correo": "ana@correo.com",
  "Pass": "clave-de-ejemplo"
}
```

`jsonEncode` transforma los datos de Dart en el texto JSON que viaja por HTTP. En C#, ese cuerpo se recibe como `ConsultaRolDTO`.

La dirección `localhost` corresponde al desarrollo en la misma PC. Cuando Flutter se ejecuta en el navegador de otro dispositivo, `localhost` se refiere a ese dispositivo, no a la PC que aloja el backend.

### Paso 4: el backend comprueba las credenciales

El controlador de C# llama a su `ServicioGeneral.ConsultarRolUsuario`.

El servicio consulta el usuario por correo, comprueba la contraseña y obtiene su rol. El controlador convierte ese resultado en una respuesta HTTP.

Las respuestas de los casos habituales del endpoint actual son:

| Caso | Código HTTP | Cuerpo JSON |
| --- | --- | --- |
| Credenciales de administrador correctas | 200 | `{"rol":"Admin"}` |
| Credenciales de cliente correctas | 200 | `{"rol":"Cliente"}` |
| Usuario inexistente o contraseña incorrecta | 401 | `{"mensaje":"Correo o contraseña incorrectos."}` |

También hay que contemplar respuestas de validación (400), errores del servidor y fallos de conexión.

### Paso 5: el servicio Dart transforma la respuesta en un DTO

`jsonDecode` convierte el texto JSON recibido en datos de Dart.

```text
Texto recibido:       {"rol":"Admin"}
Campo leído:          datos['rol']
Valor:                Admin
```

El servicio construirá un `ResultadoConsultarRol` para devolverlo al controlador. Por ejemplo:

```dart
// Ejemplo de conversión de una respuesta exitosa.
ResultadoConsultarRol(
  exito: true,
  mensaje: 'Credenciales correctas.',
  rol: 'Admin',
)
```

O, ante credenciales incorrectas:

```dart
ResultadoConsultarRol(
  exito: false,
  mensaje: 'Correo o contraseña incorrectos.',
  rol: null,
)
```

**El DTO de Dart no tiene que ser idéntico al JSON.** El backend devuelve `rol` en el caso exitoso; el servicio puede agregar `exito` y un mensaje al construir el objeto que usa el frontend.

Un HTTP 401 no lanza automáticamente una excepción en `http.post`: hay que revisar el código de respuesta. Los problemas de conexión sí pueden producir excepciones, que el servicio debe manejar.

### Paso 6: el controlador decide la respuesta de la interfaz

Cuando recibe el DTO, el controlador deberá:

- Desactivar el estado de carga.
- Si hubo un error, mostrar el mensaje y permanecer en el login.
- Si el rol es `Admin`, abrir `AdminHomeScreen`.
- Si el rol es `Cliente`, abrir su pantalla cuando exista.
- Si falta el rol o no es reconocido, mostrar un error y no navegar.

Después de una espera asíncrona, también debe comprobar que la pantalla siga abierta antes de mostrar mensajes o navegar.

El backend informa quién es el usuario y qué rol tiene; **el controlador de Flutter conoce las pantallas y decide la navegación**.

### Resumen del login

```text
Usuario toca «Ingresar»
    ↓
LoginScreen llama a ControladorGeneral
    ↓
ControladorGeneral valida el formulario
    ↓
ServicioGeneral envía correo y contraseña por HTTP
    ↓
ControladorGeneral de C# recibe la solicitud
    ↓
ServicioGeneral de C# consulta y comprueba el usuario
    ↓
Backend responde con código HTTP y JSON
    ↓
ServicioGeneral de Dart construye ResultadoConsultarRol
    ↓
ControladorGeneral de Dart muestra un error o abre una pantalla
```

Consultar el rol todavía no establece una sesión: el endpoint actual no entrega un token ni una sesión utilizable para autorizar solicitudes posteriores. Al incorporar autenticación completa, el backend deberá comprobar la sesión y los permisos en cada operación protegida. Elegir una pantalla en Flutter no protege por sí solo los endpoints.

## 5. Ejemplo ya conectado: registrar un cliente

El registro permite estudiar el mismo recorrido funcionando:

1. `RegisterScreen` dibuja el formulario y conecta el botón con el controlador.
2. `ControladorGeneral.registrarCliente` valida los campos y activa `enviando`.
3. `ServicioGeneral.registrarCliente` hace POST a `/api/controladorGeneral/nuevoCliente`.
4. El backend valida los datos y crea el usuario mediante su servicio y persistencia.
5. El servicio Dart devuelve un `ResultadoRegistro` con `exito` y `mensaje`.
6. El controlador muestra el mensaje y vuelve al login si el registro fue exitoso.

El controlador usa `notifyListeners()` para avisar que cambió su estado. La pantalla tiene un `ListenableBuilder` que escucha ese aviso y actualiza los widgets, como el botón o el indicador de carga.

## 6. ¿Por qué un DTO por operación?

Un DTO es un objeto que transporta datos entre partes del programa. No ejecuta solicitudes ni navega.

| DTO | Qué transporta |
| --- | --- |
| `ResultadoRegistro` | Éxito y mensaje del registro. |
| `ResultadoConsultarRol` | Éxito, mensaje y rol opcional de la consulta de credenciales. |

Esto permite que cada método del servicio anuncie qué devuelve y que el controlador trabaje con propiedades claras, sin interpretar JSON.

## 7. Regla rápida para ubicar código

- **¿Dibuja un campo, imagen, botón o define espacios y colores?** Pantalla o widget.
- **¿Valida el formulario, controla la carga, muestra un mensaje o navega?** Controlador de Flutter.
- **¿Llama a un endpoint o interpreta su respuesta?** Servicio de Dart.
- **¿Solo representa los datos de una operación?** DTO.
- **¿Comprueba credenciales, permisos o modifica datos persistidos?** Backend.

Para continuar leyendo el código, empezá por el registro en este orden:

1. [Pantalla de registro](../lib/screens/register_screen.dart)
2. [Controlador general](../lib/controladores/controlador_general.dart)
3. [Servicio general](../lib/servicios/servicio_general.dart)
4. [DTO del registro](../lib/dtos/resultado_registro.dart)
5. [DTO de la futura consulta del rol](../lib/dtos/resultado_consultar_rol.dart)
