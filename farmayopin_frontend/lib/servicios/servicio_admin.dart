import '../dtos/editar_producto.dart';
import '../dtos/resultado_editar_producto.dart';
import '../dtos/compra_producto.dart';
import 'dart:async';
import 'dart:typed_data';

import '../dtos/crear_producto.dart';
import '../dtos/resultado_crear_producto.dart';
import '../dtos/resultado_subir_foto.dart';
import '../dtos/producto_listado.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

// Envía las solicitudes administrativas e interpreta las respuestas del backend.
class ServicioAdmin {
  const ServicioAdmin({this.cliente});

  // En pruebas se puede inyectar un cliente HTTP sin usar un servidor real.
  final http.Client? cliente;

  Future<Map<int, String>> listarCategorias() async {
    final conexion = cliente ?? http.Client();
    try {
      final respuesta = await conexion.get(
        ApiConfig.uri('/api/controladorAdmin/categorias'),
      ).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 200) {
        throw Exception('No se pudieron cargar las categorías.');
      }
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
      return {for (final dato in datos) dato['id'] as int: dato['nombre'] as String};
    } finally {
      if (cliente == null) conexion.close();
    }
  }

  Future<ResultadoEditarProducto> editarProducto(EditarProducto producto) async {
    final http.Client conexion = cliente ?? http.Client();
    try {
      final http.Response respuesta = await conexion.put(
        ApiConfig.uri('/api/controladorAdmin/editarProducto'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'codigo': producto.codigo,
          'nombre': producto.nombre,
          'detalle': producto.detalle,
          'precio': producto.precio,
          'stock': producto.stock,
          'categoria': producto.categoria,
          'fotoUrl': producto.fotoUrl,
        }),
      ).timeout(const Duration(seconds: 20));
      if (respuesta.statusCode == 200) {
        return const ResultadoEditarProducto(true, 'Producto editado correctamente.');
      }
      return ResultadoEditarProducto(false, _leerMensaje(respuesta, 'No se pudo editar el producto.'));
    } on TimeoutException {
      return const ResultadoEditarProducto(false,
        'El servidor demoró en responder. Revisá el listado antes de reintentar: los cambios podrían haberse guardado.');
    } catch (_) {
      return const ResultadoEditarProducto(false, 'No se pudo confirmar el guardado. Revisá la conexión y reintentá.');
    } finally {
      if (cliente == null) conexion.close();
    }
  }

  Future<ResultadoCrearProducto> crearProducto(CrearProducto producto) async {
    final http.Client conexion = cliente ?? http.Client();
    try {
      final http.Response respuesta = await conexion
          .post(
            ApiConfig.uri('/api/controladorAdmin/crearProducto'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'codigo': producto.codigo,
              'nombre': producto.nombre,
              'detalle': producto.detalle,
              'precio': producto.precio,
              'stock': producto.stock,
              'categoria': producto.categoria,
              'fotoUrl': producto.fotoUrl,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (respuesta.statusCode == 201) {
        return const ResultadoCrearProducto(
          true,
          'Producto registrado correctamente.',
        );
      }
      return ResultadoCrearProducto(
        false,
        _leerMensaje(respuesta, 'No se pudo crear el producto.'),
      );
    } on TimeoutException {
      return const ResultadoCrearProducto(
        false,
        'El servidor demoró en responder. Revisá el listado antes de reintentar: el producto podría haberse guardado.',
      );
    } catch (_) {
      return const ResultadoCrearProducto(
        false,
        'No se pudo confirmar el guardado. Revisá la conexión y el listado antes de reintentar.',
      );
    } finally {
      if (cliente == null) conexion.close();
    }
  }

  Future<ResultadoSubirFoto> subirFoto(Uint8List bytes, String nombre) async {
    final http.Client conexion = cliente ?? http.Client();
    try {
      // Multipart envía los bytes del archivo; no la ruta local del celular.
      final http.MultipartRequest solicitud = http.MultipartRequest(
        'POST',
        ApiConfig.uri('/api/controladorAdmin/subirFoto'),
      );
      solicitud.files.add(
        http.MultipartFile.fromBytes('foto', bytes, filename: nombre),
      );
      final http.Response respuesta = await conexion
          .send(solicitud)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
      if (respuesta.statusCode == 201) {
        final Map<String, dynamic> datos = jsonDecode(
          utf8.decode(respuesta.bodyBytes),
        );
        final String ruta = datos['fotoUrl'] as String;
        if (ruta.isNotEmpty) {
          return ResultadoSubirFoto(true, 'Foto subida.', ruta);
        }
      }
      return ResultadoSubirFoto(
        false,
        _leerMensaje(respuesta, 'No se pudo subir la foto.'),
        null,
      );
    } catch (_) {
      return const ResultadoSubirFoto(
        false,
        'No se pudo subir la foto. Revisá la conexión y reintentá.',
        null,
      );
    } finally {
      if (cliente == null) conexion.close();
    }
  }

  String _leerMensaje(http.Response respuesta, String predeterminado) {
    if (respuesta.statusCode == 413) {
      return 'La foto supera el tamaño permitido.';
    }
    try {
      final dynamic datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is Map<String, dynamic>) {
        if (datos['mensaje'] is String) return datos['mensaje'] as String;
        // ASP.NET devuelve los errores de validación agrupados por campo.
        final dynamic errores = datos['errors'];
        if (errores is Map<String, dynamic>) {
          final List<String> mensajes = [];
          for (final dynamic erroresCampo in errores.values) {
            if (erroresCampo is List) {
              for (final dynamic mensaje in erroresCampo) {
                if (mensaje is String) mensajes.add(mensaje);
              }
            }
          }
          if (mensajes.isNotEmpty) return mensajes.join('\n');
        }
      }
    } catch (_) {
      // Un proxy puede responder HTML: mostramos un mensaje entendible.
    }
    return predeterminado;
  }

  //<--ListarProductos-->
  Future<List<ProductoListado>> listarProductos() async {
    final Uri direccion = ApiConfig.uri(
      '/api/controladorAdmin/listarProductos',
    );

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
      final Map<String, dynamic> datosProducto = dato as Map<String, dynamic>;

      final ProductoListado producto = ProductoListado.fromJson(datosProducto);

      productos.add(producto);
    }

    return productos;
  }

  Future<List<CompraProducto>> historicoProducto(int productoId) async {
    final http.Client conexion = cliente ?? http.Client();
    try {
      final http.Response respuesta = await conexion.get(
        ApiConfig.uri('/api/controladorAdmin/productos/$productoId/compras'),
      ).timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 200) {
        throw Exception(_leerMensaje(respuesta, 'No se pudieron cargar las compras.'));
      }
      final List<dynamic> datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List<dynamic>;
      final List<CompraProducto> compras = [];
      for (final dynamic dato in datos) {
        compras.add(CompraProducto.fromJson(dato as Map<String, dynamic>));
      }
      return compras;
    } finally {
      if (cliente == null) conexion.close();
    }
  }

  String funcionPendiente(String funcion) =>
      '$funcion todavía no está disponible.';
}
