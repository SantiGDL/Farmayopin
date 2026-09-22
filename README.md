# Farmayopin

Aplicación cliente-servidor desarrollada con Flutter/Dart y C#.

### Levantar Base de datos mariaDB 
En este caso se usa lampp en linux, se levanta con el siguiente comando:

```bash
sudo /opt/lampp/lampp start
```

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

