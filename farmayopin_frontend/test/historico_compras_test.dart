import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/controladores/controlador_cliente.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/cliente_home_screen.dart';
import 'package:farmayopin_frontend/screens/historico_compras_screen.dart';
import 'package:farmayopin_frontend/screens/detalle_compra_screen.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';
import 'package:farmayopin_frontend/servicios/sesion_cliente.dart';

final List<Map<String, dynamic>> compras = List.generate(9, (int indice) {
  return {
    'id': 385 - indice,
    'fechaCompra': DateTime.utc(2026, 5, 15 - indice, 13, 32).toIso8601String(),
    'precioTotal': 5700,
    'cantidadProductos': 3,
    'nombresProductos': ['Paracetamol histórico', 'Jabón'],
  };
});

final Map<String, dynamic> detalle = {
  'id': 385,
  'fechaCompra': compras.first['fechaCompra'],
  'cantidadProductos': 3,
  'subtotal': 5000,
  'envio': 700,
  'total': 5700,
  'lineas': [
    {
      'id': 1,
      'cantidad': 2,
      'subtotal': 4900,
      'producto': {
        'id': 10,
        'codigo': 'P1',
        'nombre': 'Paracetamol histórico',
        'detalle': 'Analgésico',
        'precio': 2450,
        'stock': 10,
        'categoria': 'ANALGESICOS',
        'fotoUrl': null,
        'unidad': 'TABLETA',
      },
    },
    {
      'id': 2,
      'cantidad': 1,
      'subtotal': 100,
      'producto': {
        'id': 11,
        'codigo': 'P2',
        'nombre': 'Jabón',
        'detalle': 'Higiene personal',
        'precio': 100,
        'stock': 4,
        'categoria': 'HIGIENE',
        'fotoUrl': null,
        'unidad': null,
      },
    },
  ],
};

http.Response respuestaJson(Object datos, [int codigo = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(datos)),
    codigo,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

ControladorCliente controladorHttp(
  Future<http.Response> Function(http.Request) responder,
) {
  final MockClient cliente = MockClient(responder);
  addTearDown(cliente.close);
  return ControladorCliente(servicio: ServicioCliente(cliente: cliente));
}

Future<void> pulsar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto).first);
  await tester.tap(find.text(texto).first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SesionCliente.token = 'sesion-historico';
  });
  tearDown(SesionCliente.cerrar);

  testWidgets(
    'Panel, histórico y detalle consumen API autenticada; consulta inmutable y botones Volver',
    (tester) async {
      final List<String> rutas = [];
      final ControladorCliente controlador = controladorHttp((solicitud) async {
        expect(solicitud.method, 'GET');
        expect(solicitud.headers['Authorization'], 'Bearer sesion-historico');
        expect(solicitud.url.queryParameters, isEmpty);
        rutas.add(solicitud.url.path);
        if (solicitud.url.path == '/api/controladorCliente/compras') {
          return respuestaJson(compras);
        }
        expect(solicitud.url.path, '/api/controladorCliente/compras/385');
        return respuestaJson(detalle);
      });
      await tester.pumpWidget(
        FarmayopinApp(home: ClienteHomeScreen(controlador: controlador)),
      );
      await pulsar(tester, 'Histórico de Compras');
      expect(find.byType(HistoricoComprasScreen), findsOneWidget);
      expect(find.text('#FYP-00385'), findsOneWidget);
      expect(find.text('3 productos'), findsNWidgets(7));
      await tester.ensureVisible(find.byTooltip('Ver compra #FYP-00385'));
      await tester.tap(find.byTooltip('Ver compra #FYP-00385'));
      await tester.pumpAndSettle();
      expect(find.byType(DetalleCompraScreen), findsOneWidget);
      expect(find.text('Paracetamol histórico'), findsOneWidget);
      expect(find.text(r'$2.450'), findsOneWidget);
      expect(find.text('Cantidad: 2'), findsOneWidget);
      expect(find.text(r'$5.700'), findsOneWidget);
      expect(find.byTooltip('Aumentar cantidad'), findsNothing);
      expect(find.byTooltip('Disminuir cantidad'), findsNothing);
      expect(find.byTooltip('Eliminar producto'), findsNothing);
      expect(find.text('Pagar carrito'), findsNothing);
      expect(find.text('Vitaminas'), findsNothing);
      await pulsar(tester, 'Medicamentos');
      expect(find.text('Jabón'), findsNothing);
      expect(find.text(r'$5.700'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'No existe');
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron productos.'), findsOneWidget);
      expect(find.text('Subtotal (3 productos)'), findsOneWidget);
      await pulsar(tester, 'Volver');
      expect(find.byType(HistoricoComprasScreen), findsOneWidget);
      await pulsar(tester, 'Volver');
      expect(find.byType(ClienteHomeScreen), findsOneWidget);
      expect(rutas, [
        '/api/controladorCliente/compras',
        '/api/controladorCliente/compras/385',
      ]);
    },
  );

  testWidgets(
    'Paginación real y búsqueda por pedido o nombre reinician la página',
    (tester) async {
      final ControladorCliente controlador = controladorHttp(
        (solicitud) async => respuestaJson(compras),
      );
      await tester.pumpWidget(
        FarmayopinApp(home: HistoricoComprasScreen(controlador: controlador)),
      );
      await tester.pumpAndSettle();
      expect(find.text('#FYP-00379'), findsOneWidget);
      expect(find.text('#FYP-00378'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Página siguiente'));
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('#FYP-00378'), findsOneWidget);
      expect(find.text('#FYP-00385'), findsNothing);
      await tester.enterText(find.byType(TextField), '#FYP-00385');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ver compra #FYP-00385'), findsOneWidget);
      expect(find.byTooltip('Página siguiente'), findsNothing);
      await tester.enterText(find.byType(TextField), 'PARACETAMOL');
      await tester.pumpAndSettle();
      expect(find.text('3 productos'), findsNWidgets(7));
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No se encontraron compras.'), findsOneWidget);
    },
  );

  testWidgets('Histórico vacío y compra sin líneas muestran estados vacíos', (
    tester,
  ) async {
    final ControladorCliente controlador = controladorHttp((solicitud) async {
      if (solicitud.url.path.endsWith('/compras')) return respuestaJson([]);
      return respuestaJson({
        ...detalle,
        'lineas': [],
        'cantidadProductos': 0,
        'subtotal': 0,
        'envio': 0,
        'total': 0,
      });
    });
    await tester.pumpWidget(
      FarmayopinApp(home: HistoricoComprasScreen(controlador: controlador)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todavía no realizaste compras.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Volver'), findsOneWidget);
    await tester.pumpWidget(
      FarmayopinApp(
        home: DetalleCompraScreen(compraId: 385, controlador: controlador),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Esta compra no tiene productos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Carga, error y reintento funcionan en ambas pantallas', (
    tester,
  ) async {
    for (final bool esDetalle in [false, true]) {
      final Completer<http.Response> pendiente = Completer<http.Response>();
      int llamadas = 0;
      final ControladorCliente controlador = controladorHttp((solicitud) async {
        llamadas++;
        if (llamadas == 1) return pendiente.future;
        return respuestaJson(esDetalle ? detalle : compras);
      });
      final Widget pantalla = esDetalle
          ? DetalleCompraScreen(compraId: 385, controlador: controlador)
          : HistoricoComprasScreen(controlador: controlador);
      await tester.pumpWidget(FarmayopinApp(home: pantalla));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pendiente.complete(
        respuestaJson({'mensaje': 'No se pudo consultar la compra.'}, 500),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, 'Reintentar');
      expect(
        find.text(esDetalle ? 'Paracetamol histórico' : '#FYP-00385'),
        findsOneWidget,
      );
      expect(llamadas, 2);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets(
    'Detalle 404 informa sin datos; sesión vencida y logout conservan el login',
    (tester) async {
      final ControladorCliente noExiste = controladorHttp(
        (solicitud) async => respuestaJson({
          'mensaje': 'No se encontró esa compra en tu histórico.',
        }, 404),
      );
      await tester.pumpWidget(
        FarmayopinApp(
          home: DetalleCompraScreen(compraId: 999, controlador: noExiste),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No se encontró esa compra en tu histórico.'),
        findsOneWidget,
      );
      expect(find.text('Total'), findsNothing);
      await pulsar(tester, 'Cerrar sesión');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(SesionCliente.token, isNull);
      await tester.pumpWidget(const SizedBox());
      SesionCliente.token = 'vencida';
      final ControladorCliente vencido = controladorHttp(
        (solicitud) async => respuestaJson({}, 401),
      );
      await tester.pumpWidget(
        FarmayopinApp(home: HistoricoComprasScreen(controlador: vencido)),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, 'Iniciar sesión');
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(SesionCliente.token, isNull);
    },
  );

  testWidgets('Ambas pantallas se adaptan a móvil con texto ampliado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final ControladorCliente controlador = controladorHttp((solicitud) async {
      return respuestaJson(
        solicitud.url.path.endsWith('/compras') ? compras : detalle,
      );
    });
    for (final double ancho in [320.0, 335.0]) {
      tester.view.physicalSize = Size(ancho, 1000);
      for (final Widget pantalla in [
        HistoricoComprasScreen(controlador: controlador),
        DetalleCompraScreen(compraId: 385, controlador: controlador),
      ]) {
        await tester.pumpWidget(
          FarmayopinApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: pantalla,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
