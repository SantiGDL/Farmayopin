import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/controladores/controlador_admin.dart';
import 'package:farmayopin_frontend/dtos/compra_producto.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/admin_home_screen.dart';
import 'package:farmayopin_frontend/screens/historico_producto_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_admin.dart';

const productos = [
  ProductoListado(
    'Paracetamol',
    'Analgésico',
    9999,
    248,
    'Medicamentos',
    id: 42,
    codigo: 'SKU-100',
  ),
  ProductoListado(
    'Vitamina C',
    'Vitaminas',
    200,
    30,
    'Vitaminas',
    id: 73,
    codigo: 'SKU-200',
  ),
];

class ServicioHistoricoPrueba extends ServicioAdmin {
  final List<int> consultas = [];
  bool falla = false;
  Completer<List<CompraProducto>>? pendiente;

  @override
  Future<List<ProductoListado>> listarProductos() async => productos;

  @override
  Future<List<CompraProducto>> historicoProducto(int productoId) async {
    consultas.add(productoId);
    if (falla) throw Exception('Sin conexión');
    if (pendiente != null) return pendiente!.future;
    if (productoId == 73) return [];
    return List.generate(
      8,
      (indice) => CompraProducto(
        DateTime(2026, 5, 20 - indice, 10, 32),
        indice + 1,
        100.50,
        'Cliente $indice',
        'cliente$indice@example.com',
      ),
    );
  }
}

Future<void> tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Servicio usa la PK y convierte precio histórico y fecha local',
    () async {
      final ServicioAdmin servicio = ServicioAdmin(
        cliente: MockClient((solicitud) async {
          expect(
            solicitud.url.path,
            '/api/controladorAdmin/productos/42/compras',
          );
          return http.Response.bytes(
            utf8.encode(
              jsonEncode([
                {
                  'fechaCompra': '2026-05-20T13:32:00Z',
                  'cantidadProducto': 3,
                  'precioUnitario': 100.50,
                  'nombreCliente': 'María',
                  'correoCliente': 'maria@example.com',
                },
              ]),
            ),
            200,
          );
        }),
      );
      final compras = await servicio.historicoProducto(42);
      expect(compras.single.precioUnitario, 100.50);
      expect(compras.single.nombreCliente, 'María');
      expect(
        compras.single.fechaCompra,
        DateTime.utc(2026, 5, 20, 13, 32).toLocal(),
      );
    },
  );

  test('Servicio propaga errores HTTP', () async {
    final servicio = ServicioAdmin(
      cliente: MockClient((_) async => http.Response('{}', 500)),
    );
    await expectLater(servicio.historicoProducto(42), throwsException);
  });

  testWidgets(
    'El menú Admin abre el histórico sin consultar productos ni compras',
    (tester) async {
      await tester.pumpWidget(const FarmayopinApp(home: AdminHomeScreen()));
      await tocar(tester, 'Histórico de Compras');
      expect(find.byType(HistoricoProductoScreen), findsOneWidget);
      expect(find.text('SELECCIONE PRODUCTO'), findsOneWidget);
    },
  );

  testWidgets('Selecciona, pagina, busca, cambia producto y permite cancelar', (
    tester,
  ) async {
    final servicio = ServicioHistoricoPrueba();
    await tester.pumpWidget(
      FarmayopinApp(
        home: HistoricoProductoScreen(
          controlador: ControladorAdmin(servicio: servicio),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(servicio.consultas, isEmpty);
    await tocar(tester, 'SELECCIONE PRODUCTO');
    expect(find.text('Selección de Producto Historial'), findsOneWidget);
    expect(find.text('Ver'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    await tocar(tester, 'Medicamentos');
    expect(find.text('Vitamina C'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Analgésico');
    await tester.pumpAndSettle();
    await tocar(tester, 'Paracetamol');
    expect(servicio.consultas, [42]);
    expect(find.text('248 Unidades'), findsOneWidget);
    expect(find.text(r'$100,50'), findsNWidgets(7));
    expect(find.text('cliente7@example.com'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('cliente7@example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cliente 0');
    await tester.pumpAndSettle();
    expect(find.text('cliente0@example.com'), findsOneWidget);
    expect(find.text('cliente7@example.com'), findsNothing);
    await tocar(tester, 'Cambiar producto');
    await tocar(tester, 'Volver');
    expect(servicio.consultas, [42]);
    expect(find.text('Paracetamol'), findsOneWidget);
    await tocar(tester, 'Cambiar producto');
    await tocar(tester, 'Vitamina C');
    expect(servicio.consultas, [42, 73]);
    expect(find.text('30 Unidades'), findsOneWidget);
    expect(
      find.text('No se encontraron compras para este producto.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text ?? '',
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Muestra carga, error y reintento sin perder producto', (
    tester,
  ) async {
    final servicio = ServicioHistoricoPrueba();
    servicio.pendiente = Completer<List<CompraProducto>>();
    await tester.pumpWidget(
      FarmayopinApp(
        home: HistoricoProductoScreen(
          controlador: ControladorAdmin(servicio: servicio),
        ),
      ),
    );
    await tocar(tester, 'SELECCIONE PRODUCTO');
    await tester.ensureVisible(find.text('Paracetamol'));
    await tester.tap(find.text('Paracetamol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    servicio.pendiente!.completeError(Exception('Sin conexión'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    servicio.pendiente = null;
    await tocar(tester, 'Reintentar');
    expect(servicio.consultas, [42, 42]);
    expect(find.text('cliente0@example.com'), findsOneWidget);
  });

  testWidgets('Descarta respuestas antiguas al cambiar de producto', (
    tester,
  ) async {
    final servicio = ServicioHistoricoPrueba();
    final pendiente = Completer<List<CompraProducto>>();
    servicio.pendiente = pendiente;
    await tester.pumpWidget(
      FarmayopinApp(
        home: HistoricoProductoScreen(
          controlador: ControladorAdmin(servicio: servicio),
        ),
      ),
    );
    await tocar(tester, 'SELECCIONE PRODUCTO');
    await tester.ensureVisible(find.text('Paracetamol'));
    await tester.tap(find.text('Paracetamol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    servicio.pendiente = null;
    await tester.ensureVisible(find.text('Cambiar producto'));
    await tester.tap(find.text('Cambiar producto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tocar(tester, 'Vitamina C');
    pendiente.complete([
      CompraProducto(DateTime(2026), 1, 2, 'Antiguo', 'antiguo@example.com'),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.text('No se encontraron compras para este producto.'),
      findsOneWidget,
    );
    expect(find.text('antiguo@example.com'), findsNothing);
  });

  testWidgets(
    'Histórico con texto ampliado no desborda en móvil y escritorio',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final ancho in [320.0, 412.0, 1200.0]) {
        tester.view.physicalSize = Size(ancho, 1000);
        await tester.pumpWidget(
          FarmayopinApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: HistoricoProductoScreen(
                key: ValueKey(ancho),
                controlador: ControladorAdmin(
                  servicio: ServicioHistoricoPrueba(),
                ),
              ),
            ),
          ),
        );
        await tocar(tester, 'SELECCIONE PRODUCTO');
        await tocar(tester, 'Paracetamol');
        expect(tester.takeException(), isNull);
      }
    },
  );
}
