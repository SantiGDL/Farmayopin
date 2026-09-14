# Persistencia y dependencias en Farmayopin

Apuntes del diseño que vamos a implementar para guardar usuarios en MariaDB.
Los diagramas describen el flujo previsto; agregar una dependencia todavía no conecta la base ni crea tablas.

## El recorrido de una petición

```text
Postman
   │ Envía una petición HTTP con JSON
   ▼
ControladorGeneral
   │ Recibe CrearClienteDTO y llama al servicio
   ▼
ServicioGeneral
   │ Construye Usuario, asigna el rol Cliente y pide guardarlo
   ▼
ManejadorPersistencia (EF Core)
   │ Usa el proveedor Pomelo para ejecutar SQL
   ▼
MariaDB
```

Cada pieza tiene una responsabilidad:

| Pieza | Responsabilidad |
| --- | --- |
| Postman | Enviar peticiones para probar la API. |
| ControladorGeneral | Recibir los datos HTTP, llamar al servicio y devolver una respuesta HTTP. |
| CrearClienteDTO | Definir los datos aceptados para registrar un cliente. No incluye un rol elegible por el solicitante. |
| ServicioGeneral | Ejecutar la operación: construir el usuario, asignar el rol Cliente y solicitar el guardado. |
| Usuario | Representar la entidad que se almacenará. |
| ManejadorPersistencia | Gestionar el acceso a los datos mediante Entity Framework Core. |
| Pomelo | Adaptar las operaciones de EF Core a MariaDB. |
| MariaDB | Almacenar los datos de forma persistente. |

El DTO transporta los datos de entrada; la entidad Usuario es el objeto que se prepara para almacenar:

```text
JSON → CrearClienteDTO → ServicioGeneral → Usuario → Persistencia
```

El servicio solicitará el guardado y el controlador esperará a que termine antes de devolver una respuesta de éxito. Antes de guardar contraseñas reales, hay que completar el TODO del hash: se almacena el hash, no la contraseña original.

## Qué es Entity Framework Core

Entity Framework Core (EF Core) es un ORM: permite trabajar con objetos C# y genera el SQL necesario para consultar y guardar datos. En Java, cumple un papel parecido al de Hibernate; JPA es la especificación.

La clase que crearemos se llamará **ManejadorPersistencia**. El nombre es una elección del proyecto. Lo que necesita EF Core es que herede de `DbContext`:

```csharp
// Declaración ilustrativa; falta agregar el constructor y las entidades.
public class ManejadorPersistencia : DbContext
{
}
```

`FarmayopinContext` era un nombre alternativo para esa misma clase, no una pieza adicional.

## Dependencias: Java y .NET

En .NET también se declaran dependencias en un archivo del proyecto.

| En el proyecto Java con Maven | En este proyecto .NET |
| --- | --- |
| `pom.xml` | `farmayopin_backend.csproj` |
| Dependencia declarada con `<dependency>` | Dependencia declarada con `<PackageReference>` |
| Maven resuelve y descarga las dependencias | NuGet resuelve y descarga los paquetes |

El comando:

```bash
dotnet add package Pomelo.EntityFrameworkCore.MySql --version 9.0.0
```

se ejecuta desde la carpeta que contiene el `.csproj`. Agrega la referencia al archivo y restaura los paquetes necesarios. No instala un servidor MariaDB.

La referencia queda así:

```xml
<ItemGroup>
    <PackageReference Include="Pomelo.EntityFrameworkCore.MySql"
                      Version="9.0.0" />
</ItemGroup>
```

También se puede agregar el `PackageReference` manualmente al `ItemGroup` existente del `.csproj` y después ejecutar:

```bash
dotnet restore
```

Ambas opciones declaran la misma dependencia. La línea de comandos evita tener que editar el XML a mano.

```text
Comando dotnet add package       Edición manual del .csproj
             │                              │
             ▼                              ▼
 Agrega PackageReference              dotnet restore
 y restaura paquetes                        │
             │                              │
             └──────────────┬───────────────┘
                            ▼
              Dependencia disponible en el proyecto
```

## Por qué el paquete dice MySql si usamos MariaDB

`Pomelo.EntityFrameworkCore.MySql` admite tanto MySQL como MariaDB. Aunque el paquete y su método de configuración `UseMySql` mencionen MySQL, la base del proyecto seguirá siendo **MariaDB**.

Para la versión propuesta, Pomelo `9.0.0` utiliza EF Core `9.0.x` y admite .NET `8.0+`, incluido el proyecto con destino .NET 10. La versión de .NET no obliga a que todos los paquetes tengan el mismo número de versión.

Referencia: [documentación y compatibilidad de Pomelo](https://github.com/PomeloFoundation/Pomelo.EntityFrameworkCore.MySql#compatibility).

## Próximos pasos, de a uno

1. Agregar el proveedor Pomelo al proyecto.
2. Crear ManejadorPersistencia y preparar Usuario para almacenarlo.
3. Configurar la conexión a MariaDB.
4. Crear la tabla mediante una migración y conectar el servicio con el contexto.

El primer paso solo agrega una biblioteca. La conexión, la creación de tablas y el guardado se implementan después.
