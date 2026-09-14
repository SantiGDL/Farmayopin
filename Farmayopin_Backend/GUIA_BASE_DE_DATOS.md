# Base de datos y migraciones de Farmayopin

Esta guía permite preparar una base local y mantener su estructura entre compañeros. Los comandos de .NET se ejecutan desde `Farmayopin_Backend`, donde está `farmayopin_backend.sln`. Los ejemplos de MariaDB usan XAMPP para Linux instalado en `/opt/lampp`.

## Qué implementamos

- Conexión a MariaDB mediante Entity Framework Core y el proveedor Pomelo.
- `ManejadorPersistencia`, el contexto que representa las entidades y sus relaciones.
- Registro del contexto y de `ServicioGeneral` en `Program.cs` mediante inyección de dependencias.
- Registro de clientes: controlador → servicio → `Usuarios.Add()` → `SaveChanges()` → MariaDB.
- Correo único, relación uno a uno entre usuario y carrito, y protección contra borrar productos referenciados por líneas de compra.
- Migración `Inicial`, que crea `Usuarios`, `Carritos`, `Compras`, `Productos`, `LineasDeCarrito` y `LineasDeCompra`.

Los identificadores enteros `Id` se generan automáticamente. Los enums se guardan como valores en columnas, no como tablas independientes. El registro asigna el rol Cliente y todavía no crea un carrito. El hash de contraseñas está pendiente: usar únicamente datos ficticios en esta versión.

## Preparación en otra computadora

### 1. Herramientas

Instalar el SDK de .NET 10 y MariaDB (puede ser el incluido en XAMPP). El proyecto usa EF Core 9 y Pomelo 9; la herramienta de migraciones debe ser de la rama 9 aunque el SDK sea 10.

```bash
dotnet --version
dotnet tool install --global dotnet-ef --version 9.0.20
dotnet ef --version
dotnet restore farmayopin_backend.sln
```

Si `dotnet-ef` ya está instalado y necesita esa versión, usar `dotnet tool update --global dotnet-ef --version 9.0.20`. En Linux, si no se encuentra el comando tras instalarlo, agregar `$HOME/.dotnet/tools` al `PATH` de la terminal.

### 2. Iniciar MariaDB y entrar como root

```bash
sudo /opt/lampp/lampp startmysql
sudo /opt/lampp/bin/mysql -u root -p
```

La contraseña solicitada por `sudo` es la del sistema. La de `mysql -p` es la de root de MariaDB; si la instalación local aún no tiene una configurada, presionar Enter.

`lampp` administra servicios. El cliente SQL está en `/opt/lampp/bin/mysql`; por eso `sudo mysql` puede no encontrarse. Con otra instalación o sistema operativo, usar su cliente `mariadb` o `mysql`: las instrucciones SQL siguientes son las mismas.

### 3. Crear base y usuario de conexión

Dentro de la consola SQL, para una instalación nueva:

```sql
CREATE DATABASE IF NOT EXISTS farmayopin
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER 'farmaUser'@'localhost'
    IDENTIFIED BY 'farmaPass';

GRANT ALL PRIVILEGES ON farmayopin.*
    TO 'farmaUser'@'localhost';

EXIT;
```

Estos datos son un ejemplo local de desarrollo. El usuario de MariaDB conecta el backend con la base; no es un cliente guardado en la tabla `Usuarios`. Los permisos se limitan a `farmayopin` e incluyen los necesarios para aplicar migraciones.

Si el usuario ya existe, no repetir `CREATE USER`. Para cambiar su contraseña como root:

```sql
ALTER USER 'farmaUser'@'localhost' IDENTIFIED BY 'farmaPass';
```

Si se había creado con el nombre anterior, se puede renombrar conservando permisos y contraseña:

```sql
RENAME USER 'farmayopinUser'@'localhost' TO 'farmaUser'@'localhost';
```

### 4. Configurar y probar la conexión

El archivo `farmayopin_backend/Persistencia/comunicacionMariaDB.json` debe contener:

```json
{
  "ConnectionStrings": {
    "MariaDB": "Server=localhost;Port=3306;Database=farmayopin;User=farmaUser;Password=farmaPass"
  }
}
```

Cada compañero debe adaptar los datos a su instalación. Modificar el JSON no crea ni modifica usuarios en MariaDB. Reiniciar la API después de cambiarlo: actualmente se carga con `reloadOnChange: false`.

Probar por TCP, como se conecta el backend:

```bash
/opt/lampp/bin/mysql --protocol=TCP -h localhost -P 3306 -u farmaUser -p farmayopin
```

Ingresar `farmaPass` y salir con `EXIT;`.

### 5. Crear las tablas con las migraciones existentes

Después de clonar el repositorio, ejecutar:

```bash
dotnet build farmayopin_backend
dotnet ef database update --project farmayopin_backend
```

**No ejecutar `migrations add Inicial` en cada computadora.** La migración inicial ya está en el repositorio. Cada compañero aplica esos mismos archivos a su base local. EF registra las migraciones aplicadas en `__EFMigrationsHistory`, por lo que volver a ejecutar `database update` aplica únicamente las pendientes. [Documentación de aplicación de migraciones](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying).

Con la configuración actual, MariaDB debe estar accesible también al generar migraciones porque `Program.cs` usa `ServerVersion.AutoDetect(conexion)`.

### 6. Probar la persistencia de un cliente

```bash
dotnet run --project farmayopin_backend --launch-profile http
```

Desde otra terminal:

```bash
curl -i -X POST http://localhost:5206/api/controladorGeneral/nuevoCliente \
  -H 'Content-Type: application/json' \
  -d '{"nombre":"Cliente de prueba","correo":"prueba@example.com","pass":"prueba-local","imagen":""}'
```

El controlador actual devuelve `200 OK` sin cuerpo. Para verificar el registro desde la consola SQL:

```sql
USE farmayopin;
SELECT Id, Nombre, Correo, Rol FROM Usuarios;
```

Usar un correo distinto para cada alta. El índice único bloquea los duplicados; el servicio todavía no transforma ese error en una respuesta amigable. Reiniciar la API no elimina los registros persistidos.

## Cómo mantener las migraciones

Una migración describe cambios en la estructura; no es una copia de los registros. EF compara el modelo con su snapshot para generarla. Estos archivos se versionan junto al código. [Descripción de las migraciones](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/).

La primera se generó una sola vez con:

```bash
dotnet ef migrations add Inicial --project farmayopin_backend
dotnet ef database update --project farmayopin_backend
```

Cuando alguien cambia una propiedad persistida, una relación o un índice:

1. Traer los cambios del equipo y aplicar las migraciones pendientes.
2. Modificar los modelos o `ManejadorPersistencia`.
3. Generar una migración con un nombre descriptivo, por ejemplo:

   ```bash
   dotnet ef migrations add AgregarTelefonoUsuario --project farmayopin_backend
   ```

4. Revisar el archivo generado: `Up` aplica el cambio y `Down` lo revierte. Verificar especialmente operaciones que borran columnas o tablas, porque pueden perder datos.
5. Aplicar con `dotnet ef database update --project farmayopin_backend` y comprobar la funcionalidad.
6. Subir juntos los cambios de código y todos los archivos de la migración, incluido el snapshot.

Los demás compañeros, después de traer esos cambios, solo ejecutan:

```bash
dotnet restore farmayopin_backend.sln
dotnet ef database update --project farmayopin_backend
```

No generar migraciones por cambios exclusivos en controladores o servicios que no alteren el modelo persistido. No editar tablas manualmente para cambios compartidos: esos cambios no quedan documentados en las migraciones.

Para listar migraciones:

```bash
dotnet ef migrations list --project farmayopin_backend
```

Si la última migración se generó por error y **todavía no se aplicó ni compartió**, quitarla con:

```bash
dotnet ef migrations remove --project farmayopin_backend
```

No borrar ni reescribir migraciones que los compañeros ya aplicaron: crear una nueva corrección. Coordinar los cambios de modelo para evitar migraciones simultáneas incompatibles; al integrar ramas, revisar también el snapshot. [Migraciones en equipos](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/teams).

## Qué subir a GitHub

| Elemento | Qué hacer |
| --- | --- |
| Modelos, contexto, servicios, controladores y `Program.cs` | Subir los cambios de código. |
| `.csproj` y solución | Subir; declaran los paquetes y proyectos. |
| Carpeta `farmayopin_backend/Migrations/` completa | Subir todas las migraciones, sus `.Designer.cs` y `ManejadorPersistenciaModelSnapshot.cs`. |
| Esta guía | Subir para que el equipo repita la preparación. |
| Configuración de conexión | Compartir una plantilla con datos de ejemplo; cada persona configura sus credenciales locales. |
| `bin/`, `obj/`, archivos internos de MariaDB | No subir. |
| Copias SQL con registros reales o contraseñas | No subir al repositorio. |

Actualmente `.gitignore` excluye `bin/`, `obj/` y carpetas del IDE, pero no el JSON de conexión ni copias `.sql`. La guía no cambia esa configuración. Si el JSON contiene credenciales privadas, conviene versionar un `comunicacionMariaDB.ejemplo.json`, ignorar el archivo local y copiar la plantilla al nombre requerido por `Program.cs`. Si un archivo ya está versionado, agregarlo a `.gitignore` no deja de rastrearlo ni borra su historial.

## Dónde está la base y cómo compartir datos

La base vive en el directorio de datos del servidor MariaDB, fuera del proyecto. Para conocer la ubicación exacta, ejecutar en la consola SQL:

```sql
SHOW VARIABLES LIKE 'datadir';
```

**No hace falta subir esa carpeta a GitHub.** Las migraciones recrean las tablas en cada máquina, pero no copian los clientes u otros registros que hayas ingresado.

Para compartir datos ficticios de prueba, se puede mantener un script SQL de inserciones revisado en el repositorio. Para trasladar una copia completa de estructura y datos, usar una exportación SQL. [Documentación de mariadb-dump](https://mariadb.com/docs/server/clients-and-utilities/backup-restore-and-import-clients/mariadb-dump).

En XAMPP Linux, con el backend detenido para que no haya escrituras durante esta copia local:

```bash
/opt/lampp/bin/mysqldump --protocol=TCP -h localhost -P 3306 -u farmaUser -p --single-transaction --skip-lock-tables --no-tablespaces farmayopin > "$HOME/farmayopin-respaldo.sql"
```

Ese archivo queda en tu carpeta personal, fuera del repositorio. Incluye las tablas, los registros y el historial de migraciones; no crea el usuario de conexión de MariaDB. En otras instalaciones, el programa puede llamarse `mariadb-dump`.

Para importarlo en otra computadora, primero crear la base vacía y su usuario siguiendo esta guía. Después:

```bash
/opt/lampp/bin/mysql --protocol=TCP -h localhost -P 3306 -u farmaUser -p farmayopin < "$HOME/farmayopin-respaldo.sql"
```

Importar sobre una base vacía destinada a esa copia: el volcado puede reemplazar tablas existentes. Después se pueden aplicar migraciones más nuevas con `database update`. Para el trabajo habitual del equipo, alcanza con compartir código y migraciones; no es necesario intercambiar respaldos.

## Errores habituales

- **`Build failed`**: ejecutar `dotnet build farmayopin_backend` y corregir los errores de C# antes de generar o aplicar migraciones.
- **`dotnet ef` no existe**: instalar la herramienta y comprobar el `PATH`.
- **No se puede conectar**: comprobar que MariaDB está encendido y escucha en el puerto configurado.
- **`Access denied`**: revisar usuario, contraseña y permisos; probar con el cliente usando `--protocol=TCP`.
- **`Unknown database`**: crear `farmayopin` en el servidor correcto.
- **Correo duplicado**: usar otro correo para la prueba; la restricción única está funcionando.
