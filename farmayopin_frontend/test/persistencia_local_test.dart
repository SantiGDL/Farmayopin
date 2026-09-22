import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/persistencia/persistencia_cliente.dart';
import 'package:farmayopin_frontend/screens/admin_home_screen.dart';
import 'package:farmayopin_frontend/screens/cliente_home_screen.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';
import 'package:farmayopin_frontend/servicios/sesion_cliente.dart';

final Map<String, dynamic> producto = {
  'id': 1,
  'codigo': 'SKU',
  'nombre': 'Jabón',
  'detalle': 'Higiene',
  'precio': 50,
  'stock': 20,
  'categoria': 'HIGIENE',
  'fotoUrl': null,
  'unidad': null,
};
Map<String, dynamic> carrito(int cantidad) => {
  'id': 10,
  'lineas': [
    if (cantidad > 0)
      {
        'id': 2,
        'producto': producto,
        'cantidad': cantidad,
        'subtotal': 50 * cantidad,
      },
  ],
  'cantidadProductos': cantidad,
  'subtotal': 50 * cantidad,
  'envio': 0,
  'total': 50 * cantidad,
};
final List<Map<String, dynamic>> compras = [
  {
    'id': 5,
    'fechaCompra': '2026-05-20T13:30:00Z',
    'precioTotal': 100,
    'cantidadProductos': 2,
    'nombresProductos': ['Jabón'],
  },
];
http.Response respuesta(Object datos, [int codigo = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SesionCliente.limpiarMemoria();
  });
  tearDown(SesionCliente.cerrar);

  test('Sesión sobrevive restauración y logout borra solo su clave', () async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString('preferencia_ajena', 'conservar');
    await SesionCliente.guardar(12, 'Cliente', 'token-real');
    SesionCliente.limpiarMemoria();
    await SesionCliente.restaurar();
    expect(SesionCliente.usuarioId, 12);
    expect(SesionCliente.rol, 'Cliente');
    expect(SesionCliente.token, 'token-real');
    expect(jsonDecode(preferencias.getString(SesionCliente.clave)!), {
      'usuarioId': 12,
      'rol': 'Cliente',
      'token': 'token-real',
    });
    await SesionCliente.cerrar();
    expect(preferencias.getString(SesionCliente.clave), isNull);
    expect(preferencias.getString('preferencia_ajena'), 'conservar');
    expect(SesionCliente.token, isNull);
    expect(SesionCliente.usuarioId, isNull);
    await SesionCliente.restaurar();
    expect(SesionCliente.rol, isNull);
  });

  test('Admin no conserva token del cliente anterior y sesión inválida se descarta', () async {
    await SesionCliente.guardar(1, 'Cliente', 'anterior');
    await SesionCliente.guardar(2, 'Admin', null);
    await SesionCliente.restaurar();
    expect(SesionCliente.rol, 'Admin');
    expect(SesionCliente.token, isNull);
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(SesionCliente.clave, '{datos inválidos');
    await SesionCliente.restaurar();
    expect(SesionCliente.rol, isNull);
    expect(preferencias.containsKey(SesionCliente.clave), isFalse);
  });

  testWidgets('Inicio espera sesión sin mostrar Login y restaura cada rol', (
    tester,
  ) async {
    for (final rol in ['Admin', 'Cliente']) {
      await SesionCliente.guardar(1, rol, rol == 'Cliente' ? 'token' : null);
      SesionCliente.limpiarMemoria();
      await tester.pumpWidget(FarmayopinApp(key: ValueKey(rol)));
      expect(find.byType(LoginScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(
        rol == 'Admin'
            ? find.byType(AdminHomeScreen)
            : find.byType(ClienteHomeScreen),
        findsOneWidget,
      );
    }
    await SesionCliente.cerrar();
    await tester.pumpWidget(FarmayopinApp(key: UniqueKey()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  group('SQLite real en archivo aislado', () {
    late Directory carpeta;
    late PersistenciaCliente local;
    late String ruta;
    setUp(() async {
      sqfliteFfiInit();
      carpeta = await Directory.systemTemp.createTemp('farmayopin-pruebas-');
      ruta = '${carpeta.path}/cliente.db';
      local = PersistenciaCliente(fabrica: databaseFactoryFfi, ruta: ruta);
      await SesionCliente.guardar(1, 'Cliente', 'token-1');
    });
    tearDown(() async {
      await local.cerrar();
      await carpeta.delete(recursive: true);
    });

    ServicioCliente servidor(Object datos) => ServicioCliente(
      persistencia: local,
      cliente: MockClient((_) async => respuesta(datos)),
    );
    ServicioCliente offline() => ServicioCliente(
      persistencia: local,
      cliente: MockClient(
        (_) async => throw http.ClientException('Sin conexión'),
      ),
    );

    test(
      'Historial sobrevive reapertura, no duplica y aísla usuarios',
      () async {
        await servidor(compras).verHistorico();
        await servidor(compras).verHistorico();
        await local.cerrar();
        local = PersistenciaCliente(fabrica: databaseFactoryFfi, ruta: ruta);
        final copia = await offline().verHistorico();
        expect(copia.length, 1);
        expect(copia.single.desdeCopiaLocal, isTrue);
        expect(copia.single.precioTotal, 100);
        await SesionCliente.guardar(2, 'Cliente', 'token-2');
        await expectLater(
          offline().verHistorico(),
          throwsA(
            isA<ErrorOperacionCliente>().having(
              (e) => e.mensaje,
              'mensaje',
              'No hay historial disponible sin conexión.',
            ),
          ),
        );
        await servidor([]).verHistorico();
        expect(await offline().verHistorico(), isEmpty);
        await SesionCliente.guardar(1, 'Cliente', 'nuevo-token-1');
        expect((await offline().verHistorico()).length, 1);
        await servidor([]).verHistorico();
        expect(await offline().verHistorico(), isEmpty);
      },
    );

    test(
      'Agregar, cambiar, eliminar y vaciar reflejan el carrito del servidor',
      () async {
        await servidor(carrito(2)).agregarProducto(1, 2);
        expect((await offline().verCarrito()).cantidadProductos, 2);
        await servidor(carrito(3)).cambiarCantidad(2, 3);
        await local.cerrar();
        local = PersistenciaCliente(fabrica: databaseFactoryFfi, ruta: ruta);
        expect((await offline().verCarrito()).cantidadProductos, 3);
        await servidor(carrito(0)).eliminarLinea(2);
        expect((await offline().verCarrito()).lineas, isEmpty);
        await servidor(carrito(1)).verCarrito();
        final fallido = ServicioCliente(
          persistencia: local,
          cliente: MockClient(
            (_) async => respuesta({'mensaje': 'Sin stock'}, 409),
          ),
        );
        await expectLater(
          fallido.cambiarCantidad(2, 99),
          throwsA(isA<ErrorOperacionCliente>()),
        );
        expect((await offline().verCarrito()).cantidadProductos, 1);
        await SesionCliente.guardar(2, 'Cliente', 'token-2');
        await expectLater(
          offline().verCarrito(),
          throwsA(isA<ErrorOperacionCliente>()),
        );
      },
    );

    test(
      'Compra fallida conserva carrito y confirmada vacía solo el propio',
      () async {
        await servidor(carrito(2)).verCarrito();
        await SesionCliente.guardar(2, 'Cliente', 'token-2');
        await servidor(carrito(3)).verCarrito();
        await SesionCliente.guardar(1, 'Cliente', 'token-1');
        await expectLater(offline().confirmarCompra(), throwsException);
        expect((await offline().verCarrito()).cantidadProductos, 2);
        await servidor({
          'compraId': 5,
          'subtotal': 100,
          'envio': 0,
          'total': 100,
        }).confirmarCompra();
        await local.cerrar();
        local = PersistenciaCliente(fabrica: databaseFactoryFfi, ruta: ruta);
        expect((await offline().verCarrito()).lineas, isEmpty);
        await SesionCliente.guardar(2, 'Cliente', 'token-2');
        expect((await offline().verCarrito()).cantidadProductos, 3);
      },
    );

    test('500 usa copia, 401/403 y 404 no la ocultan', () async {
      await servidor(compras).verHistorico();
      for (final codigo in [500, 401, 403, 404]) {
        final servicio = ServicioCliente(
          persistencia: local,
          cliente: MockClient(
            (_) async => respuesta({'mensaje': 'Error'}, codigo),
          ),
        );
        if (codigo == 500) {
          expect(
            (await servicio.verHistorico()).single.desdeCopiaLocal,
            isTrue,
          );
        } else if (codigo == 404) {
          await expectLater(
            servicio.verHistorico(),
            throwsA(isA<ErrorOperacionCliente>()),
          );
        } else {
          await expectLater(
            servicio.verHistorico(),
            throwsA(isA<SesionClienteVencida>()),
          );
        }
      }
    });

    test(
      'Respuesta tardía de usuario anterior no contamina nueva sesión',
      () async {
        final pendiente = Completer<http.Response>();
        final servicio = ServicioCliente(
          persistencia: local,
          cliente: MockClient((_) => pendiente.future),
        );
        final consulta = servicio.verHistorico();
        final comprobacion = expectLater(
          consulta,
          throwsA(isA<SesionClienteVencida>()),
        );
        await SesionCliente.guardar(2, 'Cliente', 'token-2');
        pendiente.complete(respuesta(compras));
        await comprobacion;
        expect(await local.leer(2, 'historial', 0), isNull);
      },
    );

    test('Detalle previamente consultado funciona offline, uno nuevo informa ausencia', () async {
      final detalle = {
        'id': 5,
        'fechaCompra': '2026-05-20T13:30:00Z',
        'lineas': [
          {'id': 8, 'producto': producto, 'cantidad': 2, 'subtotal': 100},
        ],
        'cantidadProductos': 2,
        'subtotal': 100,
        'envio': 0,
        'total': 100,
      };
      await servidor(detalle).obtenerDetalleCompra(5);
      expect((await offline().obtenerDetalleCompra(5)).desdeCopiaLocal, isTrue);
      await expectLater(
        offline().obtenerDetalleCompra(6),
        throwsA(isA<ErrorOperacionCliente>()),
      );
    });
  });
}
