import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../dtos/carrito_cliente.dart';
import '../dtos/producto_listado.dart';
import 'sesion_cliente.dart';

class ServicioCliente {
  const ServicioCliente({this.cliente});

  // En pruebas se proporciona un cliente HTTP simulado.
  final http.Client? cliente;

  Future<List<ProductoListado>> listarProductos() async {
    final http.Response respuesta = await _consultar('listarProductos', false);
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
    final http.Response respuesta = await _consultar('verCarrito', true);
    try {
      final String texto = utf8.decode(respuesta.bodyBytes);
      final Map<String, dynamic> datos =
          jsonDecode(texto) as Map<String, dynamic>;
      return CarritoCliente.fromJson(datos);
    } catch (_) {
      throw const FormatException('El servidor devolvió un carrito inválido.');
    }
  }

  Future<http.Response> _consultar(
    String operacion,
    bool requiereSesion,
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
      final http.Response respuesta = await clienteHttp
          .get(direccion, headers: encabezados)
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
        throw const SesionClienteVencida();
      }
      if (respuesta.statusCode != 200) {
        throw Exception(
          'No se pudo completar la consulta (HTTP ${respuesta.statusCode}).',
        );
      }
      return respuesta;
    } finally {
      if (cliente == null) {
        clienteHttp.close();
      }
    }
  }

  String verHistorico() {
    return 'El histórico de compras todavía no está disponible.';
  }
}

class SesionClienteVencida implements Exception {
  const SesionClienteVencida();
}
