# Farmayopin

Proyecto Flutter con la pantalla de inicio de sesión del diseño del equipo.

## Ejecutar en el navegador

Desde esta carpeta:

```bash
flutter pub get
flutter run -d web-server --web-port=8080
```

Abrir http://localhost:8080 y mantener la terminal abierta.
Para Android, iniciar un emulador o conectar el teléfono y ejecutar `flutter run`.

## Archivos de la pantalla

- `lib/main.dart`: arranque, tema y traducciones al español.
- `lib/screens/login_screen.dart`: formulario y validaciones.
- `lib/widgets/wave_background.dart`: ondas decorativas.
- `assets/images/farmayopin_logo.png`: logo extraído del PDF del equipo.
- `pubspec.yaml`: dependencias y declaración del logo.

La pantalla permite validar los campos y mostrar u ocultar la contraseña.
El método `_login()` tiene el punto de conexión pendiente con el backend:
todavía no autentica ni navega a los paneles. Registro y recuperación muestran
avisos de función pendiente.

## Verificar

```bash
flutter analyze
flutter build web
```

Los archivos de las plataformas se conservan del proyecto generado con Flutter.
`Farmayopin_Frontend_CODEX` es la copia anterior; trabajar en `farmayopin_frontend`.
