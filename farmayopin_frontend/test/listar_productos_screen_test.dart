import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/controladores/controlador_admin.dart';
import 'package:farmayopin_frontend/controladores/controlador_cliente.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/detalle_producto_screen.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';
import 'package:farmayopin_frontend/screens/ver_carrito_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';

import 'datos_cliente_prueba.dart';

class _ServicioListadoDemorado extends ServicioCliente {
  _ServicioListadoDemorado(this.resultado);
  final Completer<List<ProductoListado>> resultado;
  @override
  Future<List<ProductoListado>> listarProductos() {
    return resultado.future;
  }
}

class _ServicioListadoReintento extends ServicioCliente {
  int intentos = 0;
  @override
  Future<List<ProductoListado>> listarProductos() async {
    intentos++;
    if (intentos == 1) {
      throw Exception('Sin conexión');
    }
    return productosPrueba;
  }
}

void main() {
  const ControladorCliente cliente = ControladorCliente(
    servicio: ServicioClientePrueba(),
  );

  testWidgets('Listado administrativo conserva productos y combina filtros', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FarmayopinApp(
        home: ListarProductosScreen(
          controladorAdmin: ControladorAdmin(servicio: ServicioAdminPrueba()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Administrador'), findsOneWidget);
    await tester.ensureVisible(find.text('Vitaminas'));
    await tester.tap(find.text('Vitaminas'));
    await tester.pumpAndSettle();
    expect(find.text('Vitamina C 500 mg'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Paracetamol');
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron productos.'), findsOneWidget);
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cliente abre detalle sin acciones de admin y consulta su carrito',
    (tester) async {
      await tester.pumpWidget(
        const FarmayopinApp(
          home: ListarProductosScreen(
            esCliente: true,
            controladorCliente: cliente,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      await tester.ensureVisible(find.text('Ver').first);
      await tester.tap(find.text('Ver').first);
      await tester.pumpAndSettle();
      expect(find.byType(DetalleProductoScreen), findsOneWidget);
      expect(find.text('Editar producto'), findsNothing);
      await tester.ensureVisible(find.text('Volver a productos'));
      await tester.tap(find.text('Volver a productos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver carrito'));
      await tester.tap(find.text('Ver carrito'));
      await tester.pumpAndSettle();
      expect(find.byType(VerCarritoScreen), findsOneWidget);
      expect(find.text('Subtotal (5 productos)'), findsOneWidget);
    },
  );

  testWidgets('Carga y lista vacía son estados diferentes', (tester) async {
    final Completer<List<ProductoListado>> resultado =
        Completer<List<ProductoListado>>();
    await tester.pumpWidget(
      FarmayopinApp(
        home: ListarProductosScreen(
          esCliente: true,
          controladorCliente: ControladorCliente(
            servicio: _ServicioListadoDemorado(resultado),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No se encontraron productos.'), findsNothing);
    resultado.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron productos.'), findsOneWidget);
  });

  testWidgets('Listado permite reintentar después de un error', (tester) async {
    await tester.pumpWidget(
      FarmayopinApp(
        home: ListarProductosScreen(
          esCliente: true,
          controladorCliente: ControladorCliente(
            servicio: _ServicioListadoReintento(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar los productos.'), findsOneWidget);
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
  });

  testWidgets(
    'Catálogo se adapta a 320, 335 y 1200 píxeles con texto ampliado',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final double ancho in [320.0, 335.0, 1200.0]) {
        tester.view.physicalSize = Size(ancho, 1000);
        await tester.pumpWidget(
          const FarmayopinApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: ListarProductosScreen(
                esCliente: true,
                controladorCliente: cliente,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
