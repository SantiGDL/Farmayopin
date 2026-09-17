import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/controladores/controlador_cliente.dart';
import 'package:farmayopin_frontend/dtos/carrito_cliente.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';
import 'package:farmayopin_frontend/screens/ver_carrito_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';

import 'datos_cliente_prueba.dart';

class _ServicioCarritoDemorado extends ServicioCliente {
  _ServicioCarritoDemorado(this.resultado);
  final Completer<CarritoCliente> resultado;
  @override
  Future<CarritoCliente> verCarrito() {
    return resultado.future;
  }
}

class _ServicioCarritoReintento extends ServicioCliente {
  int intentos = 0;
  @override
  Future<CarritoCliente> verCarrito() async {
    intentos++;
    if (intentos == 1) {
      throw Exception('Sin conexión');
    }
    return carritoPrueba;
  }
}

class _ServicioSesionVencida extends ServicioCliente {
  @override
  Future<CarritoCliente> verCarrito() async {
    throw const SesionClienteVencida();
  }
}

void main() {
  const ControladorCliente controlador = ControladorCliente(
    servicio: ServicioClientePrueba(),
  );

  testWidgets('Carrito filtra productos y mantiene los importes completos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FarmayopinApp(home: VerCarritoScreen(controlador: controlador)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Subtotal (5 productos)'), findsOneWidget);
    expect(find.text(r'$5.201,50'), findsOneWidget);
    expect(find.text(r'$5.901,50'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Paracetamol');
    await tester.pumpAndSettle();
    expect(find.text('Vitamina C 500 mg'), findsNothing);
    expect(find.text(r'$5.901,50'), findsOneWidget);
    await tester.ensureVisible(find.text('Vitaminas'));
    await tester.tap(find.text('Vitaminas'));
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron productos.'), findsOneWidget);
    expect(find.text('Tu carrito está vacío.'), findsNothing);
    expect(find.text('Subtotal (5 productos)'), findsOneWidget);
  });

  testWidgets('Carrito vacío permite seguir comprando', (tester) async {
    await tester.pumpWidget(
      const FarmayopinApp(
        home: VerCarritoScreen(
          controlador: ControladorCliente(
            servicio: ServicioClientePrueba(carrito: carritoVacio),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu carrito está vacío.'), findsOneWidget);
    expect(find.text('Pagar carrito'), findsNothing);
    await tester.ensureVisible(find.text('Seguir comprando'));
    await tester.tap(find.text('Seguir comprando'));
    await tester.pumpAndSettle();
    expect(find.byType(ListarProductosScreen), findsOneWidget);
    expect(find.byType(VerCarritoScreen), findsNothing);
  });

  testWidgets(
    'Carga muestra progreso y descarta respuestas al cerrar la pantalla',
    (tester) async {
      final Completer<CarritoCliente> resultado = Completer<CarritoCliente>();
      await tester.pumpWidget(
        FarmayopinApp(
          home: VerCarritoScreen(
            controlador: ControladorCliente(
              servicio: _ServicioCarritoDemorado(resultado),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tu carrito está vacío.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      resultado.complete(carritoPrueba);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Error de conexión permite reintentar', (tester) async {
    await tester.pumpWidget(
      FarmayopinApp(
        home: VerCarritoScreen(
          controlador: ControladorCliente(
            servicio: _ServicioCarritoReintento(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal (5 productos)'), findsOneWidget);
  });

  testWidgets('Sesión vencida permite regresar al login', (tester) async {
    await tester.pumpWidget(
      FarmayopinApp(
        home: VerCarritoScreen(
          controlador: ControladorCliente(servicio: _ServicioSesionVencida()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Volvé a iniciar sesión para consultar tu carrito.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Envío no definido se muestra pendiente', (tester) async {
    const CarritoCliente sinTarifa = CarritoCliente(
      7,
      [LineaCarritoCliente(1, medicamentoPrueba, 2, 4900)],
      2,
      4900,
      null,
      null,
    );
    await tester.pumpWidget(
      const FarmayopinApp(
        home: VerCarritoScreen(
          controlador: ControladorCliente(
            servicio: ServicioClientePrueba(carrito: sinTarifa),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A confirmar'), findsNWidgets(2));
    expect(find.text(r'$4.900'), findsOneWidget);
  });

  testWidgets('Carrito se adapta a pantallas pequeñas y texto ampliado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final double ancho in [320.0, 335.0, 1200.0]) {
      tester.view.physicalSize = Size(ancho, 1000);
      await tester.pumpWidget(
        const FarmayopinApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: VerCarritoScreen(controlador: controlador),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
