import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/admin_home_screen.dart';
import 'package:farmayopin_frontend/screens/crear_producto_screen.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';

void main() {
  testWidgets('El panel se adapta a celular y texto ampliado', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in [320.0, 412.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 917);
      await tester.pumpWidget(
        FarmayopinApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const AdminHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PANEL ADMINISTRADOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Crear producto abre el formulario y cerrar sesión abre el login',
    (tester) async {
      await tester.pumpWidget(const FarmayopinApp(home: AdminHomeScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear producto'));
      await tester.tap(find.text('Crear producto'));
      await tester.pumpAndSettle();
      expect(find.byType(CrearProductoScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AdminHomeScreen), findsNothing);
    },
  );
}
