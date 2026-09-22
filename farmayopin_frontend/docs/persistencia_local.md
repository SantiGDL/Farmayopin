# Persistencia local

MariaDB sigue siendo la fuente principal. Se reutilizan los endpoints actuales de
login, carrito, confirmación de compra e histórico del cliente.

En la copia del proyecto y las referencias locales de las ramas consultadas no
había dependencias ni implementación SQLite/SharedPreferences previas.

## Sesión

`SesionCliente` conserva su nombre y sus consumidores existentes. Guarda una
única clave `farmayopin.sesion` en SharedPreferences: `usuarioId`, `rol` y el token
existente para clientes. El administrador no recibe token. No guarda contraseña,
correo ni sesión en SQLite. El endpoint de login ahora incluye el ID ya obtenido
en la validación de credenciales; no se crea otra ruta ni otra consulta.

`InicioScreen` espera la lectura antes de mostrar Admin, Cliente o Login. Cerrar
sesión elimina solo esa clave y limpia la memoria, sin borrar copias de compras
o preferencias ajenas. Los errores 401/403 conservan el tratamiento de sesión
vencida existente y nunca activan el acceso a la copia local como alternativa.

## SQLite

Archivo `farmayopin_cliente.db`, tabla `copias_cliente`, clave primaria compuesta
por `usuario_id`, `tipo` y `clave`. Los registros contienen JSON del contrato
existente y fecha de actualización. No almacenan credenciales.

- `carrito`, clave 0: última respuesta válida del carrito. Agregar, cambiar
  cantidad y eliminar actualizan la copia solo después de que MariaDB confirme
  la operación. Eliminar la última línea guarda el carrito vacío. Confirmar una
  compra guarda una copia vacía solo para su propietario. Si la compra falla,
  se mantiene el carrito. Al reiniciar se intenta leer el servidor y, si falla,
  se recupera la última copia local.
- `historial`, clave 0: listado completo descargado, reemplazado al actualizar,
  incluidas listas vacías. Esto evita duplicados y permite distinguir un historial
  vacío descargado de un historial que nunca estuvo disponible.
- `detalle`, clave del ID de compra: detalle previamente consultado. Solo estos
  detalles están disponibles offline; abrir el historial no descarga todos los
  detalles ni las imágenes.

Las consultas siempre intentan primero el servidor. Fallas de red, timeout,
respuestas inválidas y errores 5xx permiten recuperar la copia. Un 401/403 o un
error de solicitud/recurso 4xx conserva su significado y no muestra datos viejos.
Sin copia se informa que no hay historial/carrito/detalle disponible sin conexión.
Las respuestas tardías de otra sesión no se presentan al nuevo usuario.

El carrito offline es de consulta: no se encolan cambios ni pagos. Reconectarse y
recargar permite modificarlo y comprar con precios y stock actuales del backend.
Un error de escritura local no se presenta como fallo de una compra que MariaDB
ya confirmó; se registra el problema en el log y la siguiente consulta vuelve a
intentar actualizar SQLite.

## Plataformas y verificación

SQLite usa `sqflite` en Android, iOS y macOS. Web, Linux y Windows conservan los
flujos online y SharedPreferences, pero no activan esta copia SQLite. El adaptador
`sqflite_common_ffi` es solo de desarrollo, para pruebas SQLite reales en Linux.
No se agregan adaptadores Web experimentales ni se cambia la implementación Android.

Las pruebas locales usan archivos temporales, los cierran y vuelven a abrir; no
acceden a la MariaDB real ni a la base del usuario. También comprueban logout,
restauración de ambos roles, ausencia de duplicados, aislamiento de cuentas,
confirmaciones fallidas/exitosas y respuestas tardías.

```bash
flutter analyze
flutter test --dart-define=API_BASE_URL=http://localhost:5206
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5206
```

La URL localhost de las pruebas responde a una aserción existente en el test de
registro. El APK usa la dirección del host desde el emulador Android. En un equipo
físico se debe usar la dirección accesible del servidor mediante API_BASE_URL.

## Archivos de este cambio

Modificados:

- `lib/main.dart`
- `lib/controladores/controlador_general.dart`
- `lib/servicios/sesion_cliente.dart`
- `lib/servicios/servicio_general.dart`
- `lib/servicios/servicio_cliente.dart`
- `lib/dtos/resultado_iniciar_sesion.dart`
- `lib/dtos/carrito_cliente.dart`
- `lib/dtos/resumen_compra.dart`
- `lib/dtos/detalle_compra.dart`
- `lib/screens/ver_carrito_screen.dart`
- `lib/screens/confirmar_compra_screen.dart`
- `lib/screens/historico_compras_screen.dart`
- `lib/screens/detalle_compra_screen.dart`
- `pubspec.yaml` y `pubspec.lock`
- `test/formularios_test.dart`
- Backend: `Controladores/ControladorGeneral.cs`
- Registros de plugins generados automáticamente por Flutter según plataforma.

Nuevos:

- `lib/persistencia/persistencia_cliente.dart`
- `lib/screens/inicio_screen.dart`
- `test/flutter_test_config.dart`
- `test/persistencia_local_test.dart`
- `docs/persistencia_local.md`
