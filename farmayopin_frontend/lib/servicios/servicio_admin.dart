import '../dtos/producto_listado.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

// Las operaciones administrativas se conectarán aquí al controladorAdmin de C#.
// Hoy solo hay una maqueta: conservamos sus avisos, sin simular un guardado.
class ServicioAdmin {
  const ServicioAdmin();

//<--ListarProductos-->
Future<List<ProductoListado>> listarProductos() async {
  final Uri direccion = ApiConfig.uri('/api/controladorAdmin/listarProductos',);

  //Hago petición HTTPGET al endpoint 
  final http.Response respuestaBackend = await http
      .get(direccion)
      .timeout(const Duration(seconds: 15));

  if (respuestaBackend.statusCode != 200) {
    throw Exception(
      'No se pudieron cargar los productos '
      '(HTTP ${respuestaBackend.statusCode}).',
    );
  }
  //<--Si me llega HTTP la lista, lo convierto al tipo de DTO que manejo en el front y lo guardo en una variable para poder mostrarlo depués, dicho elegante:-->
  // Si el backend responde con HTTP 200, decodifico el JSON.
  // Recorro la lista y convierto cada elemento a ProductoListado.
  // Devuelvo la lista para que la pantalla pueda mostrarla.
  final String textoJson = utf8.decode(respuestaBackend.bodyBytes);

  final List<dynamic> datosBack = jsonDecode(textoJson) as List<dynamic>;

  final List<ProductoListado> productos = [];

  for (final dato in datosBack) {
    final Map<String, dynamic> datosProducto =
        dato as Map<String, dynamic>;

    final ProductoListado producto =
        ProductoListado.fromJson(datosProducto);

    productos.add(producto);
  }

  return productos;
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
