import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/admin_home_screen.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';

void main() {
  testWidgets('Listado navega, combina filtros y vuelve al menú', (
    tester,
  ) async {
    await tester.pumpWidget(const FarmayopinApp(home: AdminHomeScreen()));
    await tester.ensureVisible(find.text('Listar productos'));
    await tester.tap(find.text('Listar productos'));
    await tester.pumpAndSettle();
    expect(find.byType(ListarProductosScreen), findsOneWidget);
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
    await tester.ensureVisible(find.text('Volver'));
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listado se adapta a 320 píxeles y texto ampliado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const FarmayopinApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: ListarProductosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
