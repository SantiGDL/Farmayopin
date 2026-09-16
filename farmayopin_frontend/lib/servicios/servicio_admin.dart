import '../dtos/producto_listado.dart';

// Las operaciones administrativas se conectarán aquí al controladorAdmin de C#.
// Hoy solo hay una maqueta: conservamos sus avisos, sin simular un guardado.
class ServicioAdmin {
  const ServicioAdmin();

  // Datos de la referencia, solo para visualizar la pantalla.
  // Sustituir por la llamada HTTP cuando exista el endpoint de listado.
  List<ProductoListado> listarProductosEjemplo() {
    return const [
      ProductoListado(
        'Paracetamol 500 mg',
        'Analgésico y antipirético',
        600,
        320,
        'Medicamentos',
      ),
      ProductoListado(
        'Vitamina C 500 mg',
        'Refuerza el sistema',
        1200,
        320,
        'Vitaminas',
      ),
      ProductoListado(
        'Omeprazol 20 mg',
        'Alivia la acidez',
        2450,
        320,
        'Medicamentos',
      ),
      ProductoListado(
        'Antibacterial 250 ml',
        'Limpieza de manos',
        2450,
        320,
        'Higiene',
      ),
    ];
  }

  String funcionPendiente(String funcion) =>
      '$funcion todavía no está disponible.';
  String guardarProducto() =>
      'Esta es una maqueta: falta conectar el guardado a la API.';
  String cancelarProducto() =>
      'Cancelar volverá al menú cuando agreguemos esa pantalla.';
  String seleccionarFoto() => 'Falta implementar la selección de una foto.';
  String cerrarSesionDesdeProducto() => 'Falta conectar el cierre de sesión.';
}
