import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../dtos/carrito_cliente.dart';
import '../dtos/compra_confirmada.dart';
import '../dtos/producto_listado.dart';
import '../dtos/resumen_compra.dart';
import '../dtos/detalle_compra.dart';
import 'sesion_cliente.dart';

class ServicioCliente {
  const ServicioCliente({this.cliente});

  // En pruebas se proporciona un cliente HTTP simulado.
  final http.Client? cliente;

  Future<List<ProductoListado>> listarProductos() async {
    final http.Response respuesta = await _solicitar(
      'GET',
      'listarProductos',
      false,
      null,
    );
    try {
      final String texto = utf8.decode(respuesta.bodyBytes);
      final List<dynamic> datos = jsonDecode(texto) as List<dynamic>;
      final List<ProductoListado> productos = [];
      for (final dynamic dato in datos) {
        productos.add(ProductoListado.fromJson(dato as Map<String, dynamic>));
      }
      return productos;
    } catch (_) {
      throw const FormatException('El servidor devolvió un listado inválido.');
    }
  }

  Future<CarritoCliente> verCarrito() async {
    final http.Response respuesta = await _solicitar(
      'GET',
      'verCarrito',
      true,
      null,
    );
    return _leerCarrito(respuesta);
  }

  Future<CarritoCliente> agregarProducto(int productoId, int cantidad) async {
    final http.Response respuesta = await _solicitar(
      'POST',
      'agregarProducto',
      true,
      {'productoId': productoId, 'cantidad': cantidad},
    );
    return _leerCarrito(respuesta);
  }

  Future<CarritoCliente> cambiarCantidad(int lineaId, int cantidad) async {
    final http.Response respuesta = await _solicitar(
      'PUT',
      'lineas/$lineaId',
      true,
      {'cantidad': cantidad},
    );
    return _leerCarrito(respuesta);
  }

  Future<CarritoCliente> eliminarLinea(int lineaId) async {
    final http.Response respuesta = await _solicitar(
      'DELETE',
      'lineas/$lineaId',
      true,
      null,
    );
    return _leerCarrito(respuesta);
  }

  Future<CompraConfirmada> confirmarCompra() async {
    // No enviamos precios ni totales: el backend vuelve a calcularlos.
    final http.Response respuesta = await _solicitar(
      'POST',
      'confirmarCompra',
      true,
      null,
    );
    final Map<String, dynamic> datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    return CompraConfirmada.fromJson(datos);
  }

  CarritoCliente _leerCarrito(http.Response respuesta) {
    try {
      final String texto = utf8.decode(respuesta.bodyBytes);
      final Map<String, dynamic> datos =
          jsonDecode(texto) as Map<String, dynamic>;
      return CarritoCliente.fromJson(datos);
    } catch (_) {
      throw const FormatException('El servidor devolvió un carrito inválido.');
    }
  }

  Future<http.Response> _solicitar(
    String metodo,
    String operacion,
    bool requiereSesion,
    Map<String, dynamic>? datos,
  ) async {
    final Map<String, String> encabezados = {'Accept': 'application/json'};
    if (requiereSesion) {
      final String? token = SesionCliente.token;
      if (token == null || token.isEmpty) {
        throw const SesionClienteVencida();
      }
      encabezados['Authorization'] = 'Bearer $token';
    }

    final http.Client clienteHttp = cliente ?? http.Client();
    try {
      final Uri direccion = ApiConfig.uri('/api/controladorCliente/$operacion');
      final http.Request solicitud = http.Request(metodo, direccion);
      solicitud.headers.addAll(encabezados);
      if (datos != null) {
        solicitud.headers['Content-Type'] = 'application/json; charset=utf-8';
        solicitud.body = jsonEncode(datos);
      }
      final http.Response respuesta = await clienteHttp
          .send(solicitud)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
        throw const SesionClienteVencida();
      }
      if (respuesta.statusCode != 200) {
        String mensaje =
            'No se pudo completar la operación (HTTP ${respuesta.statusCode}).';
        try {
          final Map<String, dynamic> error = jsonDecode(
            utf8.decode(respuesta.bodyBytes),
          ) as Map<String, dynamic>;
          if (error['mensaje'] is String) {
            mensaje = error['mensaje'] as String;
          }
        } catch (_) {
          // Si no hay JSON válido, conservamos el mensaje del estado HTTP.
        }
        throw ErrorOperacionCliente(mensaje);
      }
      return respuesta;
    } finally {
      if (cliente == null) {
        clienteHttp.close();
      }
    }
  }

  Future<List<ResumenCompra>> verHistorico() async {
    final http.Response respuesta = await _solicitar(
      'GET',
      'compras',
      true,
      null,
    );
    final List<dynamic> datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as List<dynamic>;
    final List<ResumenCompra> compras = [];
    for (final dynamic compra in datos) {
      compras.add(ResumenCompra.fromJson(compra as Map<String, dynamic>));
    }
    return compras;
  }

  Future<DetalleCompra> obtenerDetalleCompra(int compraId) async {
    final http.Response respuesta = await _solicitar(
      'GET',
      'compras/$compraId',
      true,
      null,
    );
    final Map<String, dynamic> datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    return DetalleCompra.fromJson(datos);
  }
}

class SesionClienteVencida implements Exception {
  const SesionClienteVencida();
}

class ErrorOperacionCliente implements Exception {
  const ErrorOperacionCliente(this.mensaje);
  final String mensaje;
}
