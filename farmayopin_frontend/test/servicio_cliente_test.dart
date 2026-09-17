import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/dtos/carrito_cliente.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';
import 'package:farmayopin_frontend/servicios/sesion_cliente.dart';

void main() {
  final Map<String, dynamic> producto = {
    'id': 1,
    'codigo': 'P1',
    'nombre': 'Paracetamol',
    'detalle': 'Analgésico',
    'precio': 10.5,
    'stock': 12,
    'categoria': 'ANALGESICOS',
    'unidad': 'TABLETA',
    'fotoUrl': '/Imagenes/Productos/Paracetamol.jpeg',
  };
  tearDown(SesionCliente.cerrar);

  test(
    'Listado consume la ruta del cliente y conserva UTF-8 y categoría',
    () async {
      final MockClient cliente = MockClient((solicitud) async {
        expect(solicitud.method, 'GET');
        expect(solicitud.url.path, '/api/controladorCliente/listarProductos');
        return http.Response.bytes(utf8.encode(jsonEncode([producto])), 200);
      });
      addTearDown(cliente.close);
      final List<ProductoListado> productos = await ServicioCliente(
        cliente: cliente,
      ).listarProductos();
      expect(productos.single.descripcion, 'Analgésico');
      expect(productos.single.categoria, 'Medicamentos');
      expect(productos.single.precio, 10.5);
    },
  );

  test('Carrito envía el token y usa los totales del backend', () async {
    SesionCliente.token = 'token-prueba';
    final MockClient cliente = MockClient((solicitud) async {
      expect(solicitud.method, 'GET');
      expect(solicitud.url.path, '/api/controladorCliente/verCarrito');
      expect(solicitud.url.queryParameters, isEmpty);
      expect(solicitud.headers['Authorization'], 'Bearer token-prueba');
      return http.Response(
        jsonEncode({
          'id': 7,
          'lineas': [
            {'id': 3, 'producto': producto, 'cantidad': 2, 'subtotal': 21},
          ],
          'cantidadProductos': 2,
          'subtotal': 21,
          'envio': 700,
          'total': 721,
        }),
        200,
      );
    });
    addTearDown(cliente.close);
    final CarritoCliente carrito = await ServicioCliente(cliente: cliente)
        .verCarrito();
    expect(carrito.lineas.single.cantidad, 2);
    expect(carrito.lineas.single.subtotal, 21);
    expect(carrito.cantidadProductos, 2);
    expect(carrito.total, 721);
  });

  test(
    'Carrito vacío y envío sin definir se interpretan sin inventar datos',
    () async {
      SesionCliente.token = 'token-prueba';
      final MockClient cliente = MockClient((solicitud) async {
        return http.Response(
          jsonEncode({
            'id': null,
            'lineas': [],
            'cantidadProductos': 0,
            'subtotal': 0,
            'envio': null,
            'total': null,
          }),
          200,
        );
      });
      addTearDown(cliente.close);
      final CarritoCliente carrito = await ServicioCliente(cliente: cliente)
          .verCarrito();
      expect(carrito.lineas, isEmpty);
      expect(carrito.envio, isNull);
      expect(carrito.total, isNull);
    },
  );

  test('Sin sesión no se envía ninguna consulta del carrito', () async {
    final MockClient cliente = MockClient((solicitud) async {
      fail('No debe consultar sin token.');
    });
    addTearDown(cliente.close);
    await expectLater(
      ServicioCliente(cliente: cliente).verCarrito(),
      throwsA(isA<SesionClienteVencida>()),
    );
  });

  test(
    '401, 403, 500, JSON inválido y fallo de red no se confunden con vacío',
    () async {
      SesionCliente.token = 'token-prueba';
      for (final int codigo in [401, 403, 500]) {
        final MockClient cliente = MockClient((solicitud) async {
          return http.Response('', codigo);
        });
        addTearDown(cliente.close);
        if (codigo == 401 || codigo == 403) {
          await expectLater(
            ServicioCliente(cliente: cliente).verCarrito(),
            throwsA(isA<SesionClienteVencida>()),
          );
        } else {
          await expectLater(
            ServicioCliente(cliente: cliente).verCarrito(),
            throwsException,
          );
        }
      }
      final MockClient invalido = MockClient((solicitud) async {
        return http.Response('no es JSON', 200);
      });
      addTearDown(invalido.close);
      await expectLater(
        ServicioCliente(cliente: invalido).listarProductos(),
        throwsFormatException,
      );
      final MockClient desconectado = MockClient((solicitud) async {
        throw http.ClientException('Sin conexión');
      });
      addTearDown(desconectado.close);
      await expectLater(
        ServicioCliente(cliente: desconectado).verCarrito(),
        throwsException,
      );
    },
  );
}
