import 'package:flutter/foundation.dart';

import '../persistencia/persistencia_cliente.dart';

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
  const ServicioCliente({this.cliente, this.persistencia});

  // En pruebas se proporciona un cliente HTTP simulado.
  final http.Client? cliente;
  final PersistenciaCliente? persistencia;
  PersistenciaCliente get _local =>
      persistencia ?? PersistenciaCliente.instancia;

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

  Future<CarritoCliente> verCarrito() {
    return _consultarConCopia('verCarrito', 'carrito', 0, (
      String texto,
      bool local,
    ) {
      final Map<String, dynamic> datos =
          jsonDecode(texto) as Map<String, dynamic>;
      return CarritoCliente.fromJson({...datos, 'desdeCopiaLocal': local});
    });
  }

  Future<CarritoCliente> agregarProducto(int productoId, int cantidad) {
    return _modificarCarrito('POST', 'agregarProducto', {
      'productoId': productoId,
      'cantidad': cantidad,
    });
  }

  Future<CarritoCliente> cambiarCantidad(int lineaId, int cantidad) {
    return _modificarCarrito('PUT', 'lineas/$lineaId', {'cantidad': cantidad});
  }

  Future<CarritoCliente> eliminarLinea(int lineaId) {
    return _modificarCarrito('DELETE', 'lineas/$lineaId', null);
  }

  Future<CarritoCliente> _modificarCarrito(
    String metodo,
    String ruta,
    Map<String, dynamic>? datos,
  ) async {
    final int? usuarioId = SesionCliente.usuarioId;
    final http.Response respuesta = await _solicitar(metodo, ruta, true, datos);
    final CarritoCliente carrito = _leerCarrito(respuesta);
    await _guardarCopia(
      usuarioId,
      'carrito',
      0,
      utf8.decode(respuesta.bodyBytes),
    );
    return carrito;
  }

  Future<CompraConfirmada> confirmarCompra() async {
    final int? usuarioId = SesionCliente.usuarioId;
    // No enviamos precios ni totales: el backend vuelve a calcularlos.
    final http.Response respuesta = await _solicitar(
      'POST',
      'confirmarCompra',
      true,
      null,
    );
    final Map<String, dynamic> datos =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    final CompraConfirmada compra = CompraConfirmada.fromJson(datos);
    // Reemplaza la copia por un carrito vacío únicamente tras confirmación real.
    await _guardarCopia(
      usuarioId,
      'carrito',
      0,
      jsonEncode({
        'id': null,
        'lineas': [],
        'cantidadProductos': 0,
        'subtotal': 0,
        'envio': 0,
        'total': 0,
      }),
    );
    return compra;
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
    final String? tokenInicial = SesionCliente.token;
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

      // Una respuesta tardía de la sesión anterior no llega a la nueva pantalla.
      if (requiereSesion && tokenInicial != SesionCliente.token) {
        throw const SesionClienteVencida();
      }
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
        throw ErrorOperacionCliente(mensaje, respuesta.statusCode);
      }
      return respuesta;
    } finally {
      if (cliente == null) {
        clienteHttp.close();
      }
    }
  }

  Future<List<ResumenCompra>> verHistorico() {
    return _consultarConCopia('compras', 'historial', 0, (
      String texto,
      bool local,
    ) {
      final List<dynamic> datos = jsonDecode(texto) as List<dynamic>;
      final List<ResumenCompra> compras = [];
      for (final dynamic compra in datos) {
        compras.add(
          ResumenCompra.fromJson({
            ...compra as Map<String, dynamic>,
            'desdeCopiaLocal': local,
          }),
        );
      }
      return compras;
    });
  }

  Future<DetalleCompra> obtenerDetalleCompra(int compraId) {
    return _consultarConCopia('compras/$compraId', 'detalle', compraId, (
      String texto,
      bool local,
    ) {
      final Map<String, dynamic> datos =
          jsonDecode(texto) as Map<String, dynamic>;
      return DetalleCompra.fromJson({...datos, 'desdeCopiaLocal': local});
    });
  }

  // Primero servidor. La copia se reemplaza completa: una descarga repetida
  // no duplica compras y una lista vacía también queda guardada.
  Future<T> _consultarConCopia<T>(
    String ruta,
    String tipo,
    int clave,
    T Function(String, bool) convertir,
  ) async {
    final int? usuarioId = SesionCliente.usuarioId;
    final String? token = SesionCliente.token;
    try {
      final http.Response respuesta = await _solicitar('GET', ruta, true, null);
      final String texto = utf8.decode(respuesta.bodyBytes);
      final T resultado = convertir(texto, false);
      await _guardarCopia(usuarioId, tipo, clave, texto);
      if (token != SesionCliente.token ||
          usuarioId != SesionCliente.usuarioId) {
        throw const SesionClienteVencida();
      }
      return resultado;
    } on SesionClienteVencida {
      rethrow;
    } catch (error) {
      // Un 401/403 o un recurso inexistente no autoriza a mostrar datos viejos.
      if (error is ErrorOperacionCliente &&
          error.codigoHttp != null &&
          error.codigoHttp! < 500) {
        rethrow;
      }
      if (token != SesionCliente.token ||
          usuarioId != SesionCliente.usuarioId) {
        throw const SesionClienteVencida();
      }
      if (usuarioId != null) {
        try {
          final String? copia = await _local.leer(usuarioId, tipo, clave);
          if (token != SesionCliente.token ||
              usuarioId != SesionCliente.usuarioId) {
            throw const SesionClienteVencida();
          }
          if (copia != null) return convertir(copia, true);
        } on SesionClienteVencida {
          rethrow;
        } catch (_) {
          debugPrint('No se pudo leer la copia local de $tipo.');
        }
      }
      final String mensaje;
      if (tipo == 'historial') {
        mensaje = 'No hay historial disponible sin conexión.';
      } else if (tipo == 'detalle') {
        mensaje = 'No hay detalle disponible sin conexión. Consultá esta compra con conexión primero.';
      } else {
        mensaje = 'No hay carrito disponible sin conexión.';
      }
      throw ErrorOperacionCliente(mensaje);
    }
  }

  Future<void> _guardarCopia(
    int? usuarioId,
    String tipo,
    int clave,
    String texto,
  ) async {
    if (usuarioId == null) return;
    try {
      await _local.guardar(usuarioId, tipo, clave, texto);
    } catch (_) {
      // Una falla de almacenamiento no transforma una compra confirmada en
      // un pago fallido ni descarta datos válidos recibidos de MariaDB.
      debugPrint('No se pudo actualizar la copia local de $tipo.');
    }
  }
}

class SesionClienteVencida implements Exception {
  const SesionClienteVencida();
}

class ErrorOperacionCliente implements Exception {
  const ErrorOperacionCliente(this.mensaje, [this.codigoHttp]);
  final String mensaje;
  final int? codigoHttp;
}
