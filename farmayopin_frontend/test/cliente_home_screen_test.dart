import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/cliente_home_screen.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';
import 'package:farmayopin_frontend/controladores/controlador_cliente.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';
import 'package:farmayopin_frontend/screens/ver_carrito_screen.dart';
import 'package:farmayopin_frontend/screens/historico_compras_screen.dart';
import 'package:farmayopin_frontend/servicios/sesion_cliente.dart';

import 'datos_cliente_prueba.dart';

void main() {
  testWidgets('Panel cliente carga assets y se adapta a distintos anchos', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final double ancho in [320.0, 412.0, 1200.0]) {
      tester.view.physicalSize = Size(ancho, 1000);
      await tester.pumpWidget(
        const FarmayopinApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: ClienteHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PANEL DE CLIENTE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Accesos abren catálogo y carrito; cerrar sesión elimina el token',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SesionCliente.token = 'token-prueba';
      addTearDown(SesionCliente.cerrar);
      await tester.pumpWidget(
        const FarmayopinApp(
          home: ClienteHomeScreen(
            controlador: ControladorCliente(servicio: ServicioClientePrueba()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final String titulo in [
        'Ver Productos',
        'Mi Carrito',
        'Histórico de Compras',
      ]) {
        await tester.ensureVisible(find.text(titulo));
        await tester.tap(find.text(titulo));
        await tester.pumpAndSettle();
        if (titulo == 'Histórico de Compras') {
          expect(find.byType(HistoricoComprasScreen), findsOneWidget);
        } else {
          if (titulo == 'Ver Productos') {
            expect(find.byType(ListarProductosScreen), findsOneWidget);
          } else {
            expect(find.byType(VerCarritoScreen), findsOneWidget);
          }
        }
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ClienteHomeScreen), findsNothing);
      expect(SesionCliente.token, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
