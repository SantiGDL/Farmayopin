# Farmayopin

Aplicación cliente-servidor desarrollada con Flutter/Dart y C#.

### Levantar Base de datos mariaDB 
En este caso se usa lampp en linux, se levanta con el siguiente comando:

```bash
sudo /opt/lampp/lampp start
```

## Actualizar la estructura de la base de datos con migraciones

Si otro integrante agregó migraciones al repositorio, primero descargá los cambios con `git pull` desde la raíz del proyecto. Necesitás el SDK .NET 10, MariaDB encendido y la conexión de tu equipo configurada en `Farmayopin_Backend/farmayopin_backend/Persistencia/comunicacionMariaDB.json` (servidor, puerto, base, usuario y contraseña).

Si todavía no tenés la herramienta de Entity Framework, instalala una vez. El backend utiliza EF Core 9:

```bash
dotnet tool install --global dotnet-ef --version 9.0.20
```

Si ya tenés una versión anterior de la herramienta, actualizala con `dotnet tool update --global dotnet-ef --version 9.0.20`.

Para aplicar las migraciones pendientes, comenzá desde la raíz del proyecto:

```bash
cd Farmayopin_Backend/farmayopin_backend
dotnet restore
dotnet ef database update
```

El comando usa la conexión configurada y consulta `__EFMigrationsHistory` para aplicar las migraciones que faltan. Si la base ya está actualizada, no vuelve a aplicarlas. Esto actualiza la estructura según las migraciones del repositorio; no copia los productos, usuarios ni compras de otro equipo.

Para consultar las migraciones disponibles y cuáles están pendientes, desde esa misma carpeta:

```bash
dotnet ef migrations list
```

No hace falta ejecutar `dotnet ef migrations add` para ponerse al día: ese comando se usa cuando se modifica el modelo y se necesita crear una migración nueva.

Referencia: [herramientas de Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/cli/dotnet).

## Comandos para levantar el proyecto desde la carpeta raíz

Ejecutá cada comando en una terminal distinta, comenzando desde la carpeta raíz del proyecto.

### Backend

```bash
dotnet run --project Farmayopin_Backend/farmayopin_backend --launch-profile http
```

### Frontend version Web

```bash
cd farmayopin_frontend && flutter run -d web-server --web-port 8080
```


### Frontend version Emulador Android

Primero hay que iniciar un emulador Android desde Android Studio.

En este proyecto se usó el Pixel 6 con Android 15 por ser una opción moderna y liviana.

Luego de iniciado hay que verificar los dispositivos disponibles con:

```bash
cd farmayopin_frontend && flutter devices
```

Después ejecutar la app Flutter en el emulador con: 

```bash
cd farmayopin_frontend && flutter run -d emulator-5554
```

El identificador emulator-5554 puede variar según el dispositivo virtual.
Se utiliza flutter devices para consultar el identificador correcto.

### Conexión con el backend desde el emulador (en caso de querer llamar un endpoint al backend o comprobar una alguna funcionalidad)

Para acceder al backend ejecutándose en la PC anfitriona, se debe utilizar:

http://10.0.2.2:PUERTO

en este caso 

http://10.0.2.2:5206

### Comandos para ajustar imagen del emulador android

En este caso como se utiliza una pantalla de 720 x 1280 se ajustaron las dimesiones del celular usando los siguientes comandos: 

```bash
adb shell wm size 540x1200
adb shell wm density 210
```
