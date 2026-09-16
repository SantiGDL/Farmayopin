// Las operaciones administrativas se conectarán aquí al controladorAdmin de C#.
// Hoy solo hay una maqueta: conservamos sus avisos, sin simular un guardado.
class ServicioAdmin {
  const ServicioAdmin();

  String funcionPendiente(String funcion) =>
      '$funcion todavía no está disponible.';
  String guardarProducto() =>
      'Esta es una maqueta: falta conectar el guardado a la API.';
  String cancelarProducto() =>
      'Cancelar volverá al menú cuando agreguemos esa pantalla.';
  String seleccionarFoto() => 'Falta implementar la selección de una foto.';
  String cerrarSesionDesdeProducto() => 'Falta conectar el cierre de sesión.';
}
