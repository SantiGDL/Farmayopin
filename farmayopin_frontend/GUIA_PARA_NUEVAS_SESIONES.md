# Guía para continuar Farmayopin en una nueva sesión

## Leer primero

El usuario conoce C# y Java, y algo de HTML/CSS. Está aprendiendo Dart y Flutter mientras desarrolla este proyecto. **Prefiere más líneas de código si eso permite comprender cada paso.** La prioridad es que pueda estudiar, explicar y mantener lo que se genera.

Antes de modificar lógica, leer especialmente:

- [`ControladorGeneral.iniciarSesion`](lib/controladores/controlador_general.dart).
- [`ServicioGeneral.iniciarSesion`](lib/servicios/servicio_general.dart).
- [`ResultadoIniciarSesion`](lib/dtos/resultado_iniciar_sesion.dart).

Estos métodos fueron construidos a mano con el usuario y son la referencia principal de estilo. Otros métodos antiguos pueden usar expresiones más compactas: no tomarlos como preferencia del usuario. Mantener la claridad de esos ejemplos, sin copiar errores de escritura o formato.

## Arquitectura acordada

```text
Pantalla Flutter
    → Controlador Dart (General / Admin / Cliente)
        → Servicio Dart del mismo grupo
            → Endpoint del backend C#
                → Controlador C# → Servicio C# → Persistencia / BD
```

La respuesta recorre el camino inverso. La agrupación replica la forma de pensar del backend:

| Grupo | Responsabilidades |
| --- | --- |
| General | Registro, login y acciones compartidas. |
| Admin | Panel y funciones administrativas. |
| Cliente | Panel, catálogo, carrito e histórico del cliente. |

### Pantallas: `lib/screens/`

- Dibujan campos, textos, imágenes, botones y distribución visual.
- Conectan eventos con el controlador correspondiente.
- Dividen el diseño en métodos pequeños: encabezado, bienvenida, opciones, etc.
- Pueden calcular anchos y adaptar el diseño: eso es presentación.
- No envían HTTP, interpretan JSON ni deciden reglas de negocio.
- En pantallas con estado, crean y liberan su controlador y escuchan sus cambios.

### Controladores: `lib/controladores/`

- Reciben las acciones de la pantalla y llaman al servicio de su grupo.
- Leen campos, ejecutan validadores y administran estado como `enviando`.
- Reciben DTO, muestran mensajes y deciden la navegación.
- Pueden usar Flutter y `BuildContext`; los servicios no.
- Después de `await`, comprueban que el contexto siga montado antes de navegar o mostrar mensajes. Evitan notificar a controladores ya liberados.
- Usan `ChangeNotifier` y `notifyListeners()` cuando necesitan actualizar la vista; esta escucha con `ListenableBuilder`.
- Cada formulario tiene su propia instancia del controlador para no compartir contraseñas ni campos accidentalmente.

### Servicios: `lib/servicios/`

- Llaman a los endpoints y envían datos con HTTP/JSON.
- Interpretan códigos HTTP y cuerpos JSON.
- Devuelven un DTO concreto por operación.
- Manejan errores de conexión y de interpretación de la respuesta.
- No conocen widgets, `BuildContext`, `Navigator` ni `SnackBar`.
- Solicitan la validación o creación al backend: no reemplazan la autenticación, autorización o persistencia de C#.

### DTO: `lib/dtos/`

El usuario prefiere **un DTO por operación**, como en C#.

- `ResultadoRegistro`: `exito` y `mensaje`.
- `ResultadoIniciarSesion`: `exito`, `mensaje` y `rol` opcional.

No volver a introducir un resultado genérico `ResultadoOperacion` para reemplazarlos. Los DTO transportan datos; no llaman endpoints ni navegan. El servicio convierte el JSON en el DTO: este no tiene que reproducir exactamente todos los campos del JSON.

## Estilo de código preferido

1. **Tipos explícitos**, especialmente para variables que ayudan a entender el flujo:

   ```dart
   final String correo = correoController.text;
   final http.Response respuestaBackend = await _cliente.post(...);
   final Map<String, dynamic> respuesta = jsonDecode(respuestaBackend.body);
   ```

   El ejemplo de HTTP es esquemático: los puntos suspensivos no son código para copiar.

2. **Parámetros posicionales en nuevos métodos propios**, como:

   ```dart
   Future<ResultadoIniciarSesion> iniciarSesion(
     String correo,
     String password,
   ) async {
     // ...
   }
   ```

   Llamada: `await _servicio.iniciarSesion(correo, password)`.
   Respetar parámetros con nombre cuando la API de Flutter o de un paquete los exige, como `headers:` y `body:`. Hay constructores propios existentes con parámetros nombrados; no cambiar todas sus firmas por iniciativa propia fuera del alcance de la tarea.

3. **Un paso por línea y variables intermedias descriptivas.** Preferir:

   ```dart
   final FormState? formulario = formKey.currentState;
   if (formulario == null) {
     return;
   }

   final bool formularioValido = formulario.validate();
   if (formularioValido == false) {
     return;
   }
   ```

   En lugar de concentrar todo en `if (!formKey.currentState!.validate()) return;`.

4. Usar nombres claros, preferentemente en español para lógica propia: `referenciaPantalla`, `respuestaBackend`, `formularioValido`. Respetar nombres públicos existentes y las convenciones de Flutter.
5. Preferir `if/else` explícitos a ternarios anidados, cascadas `..`, cadenas largas o expresiones compactas difíciles de seguir.
6. Cuando una función anónima contiene lógica, mostrar su cuerpo con llaves y `return` en vez de comprimirlo con `=>`.
7. Agregar comentarios en español que expliquen intención, recorrido y conceptos nuevos. No hace falta comentar cada cierre de llave.
8. Mantener métodos pequeños y con responsabilidad clara. No crear capas, interfaces, paquetes de estado o patrones nuevos solo para parecer más sofisticado.
9. No eliminar validaciones o manejo de errores necesarios para acortar el código. A la vez, no presentar como obligatorias comprobaciones defensivas redundantes con el contrato real del backend: revisar primero ese contrato y explicar el motivo.
10. Usar formato consistente; no reescribir archivos ajenos a la tarea solo para reformatearlos.

## Cómo acompañar al usuario

Hay dos modalidades y es importante distinguirlas:

- Si pide **generar una pantalla, aplicar un cambio o refactorizar**, hacer el trabajo completo dentro de lo pedido, conservando su estilo y arquitectura.
- Si pide **que lo guíen para aprender**, no editar sus archivos ni entregar toda la solución de golpe. Dar un paso pequeño, explicar qué significa y dejar que lo escriba. Luego continuar sobre su avance.

El usuario pidió explícitamente ir más despacio durante el login. No entregar un método entero cuando está preguntando por una línea o un tipo.

Para explicar sintaxis, usar comparaciones con C#/Java y HTML/CSS. Diferenciar el nombre de una variable de su tipo, y las responsabilidades de cada capa. `BuildContext` representa una ubicación en el árbol de widgets: no es una URL ni el widget completo.

## Referencia del flujo de login

1. `LoginScreen` llama a `ControladorGeneral.iniciarSesion` con su contexto.
2. El controlador obtiene `FormState`, comprueba que exista y ejecuta `validate()`.
3. Lee `correoController.text` y `passwordController.text` en variables explícitas.
4. Espera `ServicioGeneral.iniciarSesion(correo, password)`.
5. El servicio hace POST a `/api/controladorGeneral/consultarRolUsuario`, enviando `Correo` y `Pass`.
6. El backend comprueba credenciales y responde con `{"rol":"Admin"}` o `{"rol":"Cliente"}`; para credenciales incorrectas devuelve 401.
7. El servicio construye `ResultadoIniciarSesion`.
8. El controlador verifica `mounted`, muestra el mensaje si falló y navega al panel correspondiente si tuvo éxito.

Consultar credenciales y rol se hace en una sola solicitud; no duplicarlo en dos peticiones sin una necesidad concreta. Un código 401 es una respuesta HTTP y no activa por sí solo el `catch` de `http.post`.

## Estado al escribir esta guía

Comprobar siempre el código actual: esta sección puede quedar desactualizada.

- Registro conectado al backend local `http://localhost:5206`.
- Login conectado al endpoint de credenciales y navegación por rol.
- Panel administrador: `AdminHomeScreen`.
- Panel cliente: `ClienteHomeScreen`, ya conectado para el rol `Cliente`.
- Crear producto sigue siendo una maqueta; los accesos pendientes muestran avisos.
- Catálogo, carrito e histórico del cliente todavía no están implementados.
- No hay sesión/token ni protección completa de endpoints. Navegar al panel no equivale a completar esa protección.
- Los íconos compartidos están en **`assets/Iconos/`** (respetar mayúsculas).
- Logo: `assets/images/farmayopin_logo.png`.
- Capturas de referencia en `assets/images/`.
- `pubspec.yaml` declara `assets/Iconos/`. No reutilizar las rutas antiguas de `Admin_PantallaPrincipal`.
- El usuario aceptó que los paneles mantengan un ancho limitado y centrado en escritorio para conservar el diseño móvil. Respetar esa decisión.
- Las ondas del fondo usan `#D3FDF0`; registro muestra solo la onda inferior.

## Al generar una nueva pantalla

1. Leer las referencias del login y revisar el controlador/servicio del grupo correspondiente.
2. Revisar los assets reales y la captura; reutilizarlos y actualizar `pubspec.yaml` si corresponde.
3. Construir la vista con métodos pequeños y comentarios comprensibles.
4. Colocar las acciones en el controlador del grupo y las operaciones HTTP en su servicio.
5. Crear DTO específicos cuando la operación los necesite.
6. Conectar la navegación autorizada por la tarea. No dejar una pantalla inaccesible sin explicar cómo abrirla.
7. Para funciones aún no implementadas, mostrar avisos claros. No simular compras ni inventar contadores.
8. Ejecutar análisis y pruebas relevantes. Distinguir comprobaciones automáticas de una prueba real con backend.
9. Conservar cambios manuales del usuario. Los buffers del editor pueden no estar guardados: si el archivo en disco difiere de lo que comparte, señalarlo.

## Texto para iniciar otra sesión

> Leé `farmayopin_frontend/GUIA_PARA_NUEVAS_SESIONES.md` antes de trabajar. Seguí la arquitectura por General/Admin/Cliente y el estilo explícito de `iniciarSesion` en `ControladorGeneral` y `ServicioGeneral`. Prefiero código comprensible, aunque ocupe más líneas. Si te pido guía, avanzá de a un paso; si te pido generar una pantalla, implementala siguiendo esas reglas.
