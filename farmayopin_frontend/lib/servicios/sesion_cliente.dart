// Conserva únicamente el token mientras la aplicación está abierta.
// Al cerrar sesión se elimina; nunca guardamos la contraseña del cliente.
class SesionCliente {
  static String? token;

  static void cerrar() {
    token = null;
  }
}
