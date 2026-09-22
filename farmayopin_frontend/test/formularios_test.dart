import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/login_screen.dart';
import 'package:farmayopin_frontend/screens/register_screen.dart';

void main() {
  testWidgets(
    'Login conserva validación, visibilidad y navegación a registro',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const FarmayopinApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar'));
      await tester.pump();
      expect(find.text('Ingresá tu correo electrónico.'), findsOneWidget);
      expect(find.text('Ingresá tu contraseña.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@correo.com',
      );
      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
      // El login ya consulta la API; su contrato se verifica con MockClient
      // en servicio_general_test, sin enviar credenciales desde esta prueba visual.
      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));
      await tester.pump();
      expect(find.text('Ingresá tu nombre completo.'), findsOneWidget);
      expect(find.text('Confirmá tu contraseña.'), findsOneWidget);
      await tester.ensureVisible(find.text('Ya tengo cuenta'));
      await tester.tap(find.text('Ya tengo cuenta'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
