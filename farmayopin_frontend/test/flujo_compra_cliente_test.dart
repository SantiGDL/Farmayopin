import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmayopin_frontend/controladores/controlador_cliente.dart';
import 'package:farmayopin_frontend/dtos/compra_confirmada.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/cliente_home_screen.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';
import 'package:farmayopin_frontend/screens/detalle_producto_screen.dart';
import 'package:farmayopin_frontend/screens/ver_carrito_screen.dart';
import 'package:farmayopin_frontend/screens/confirmar_compra_screen.dart';

import 'datos_cliente_prueba.dart';

Future<void> pulsar(WidgetTester tester, String texto) async {
  // Esperamos que termine el aviso temporal antes de tocar botones inferiores.
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  final Finder boton = find.text(texto).first;
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Listado agrega uno, detalle usa cantidad y navegación reutiliza catálogo',
    (tester) async {
      final ServicioFlujoPrueba servicio = ServicioFlujoPrueba();
      await tester.pumpWidget(
        FarmayopinApp(
          home: ClienteHomeScreen(
            controlador: ControladorCliente(servicio: servicio),
          ),
        ),
      );
      await pulsar(tester, 'Ver Productos');
      await pulsar(tester, 'Agregar');
      expect(servicio.ultimaCantidad, 1);
      expect(find.byType(ListarProductosScreen), findsOneWidget);
      expect(find.byType(VerCarritoScreen), findsNothing);
      await pulsar(tester, 'Ver');
      expect(find.byType(DetalleProductoScreen), findsOneWidget);
      final Finder aumentar = find.byTooltip('Aumentar cantidad');
      await tester.ensureVisible(aumentar);
      await tester.tap(aumentar);
      await tester.pumpAndSettle();
      await pulsar(tester, 'Agregar al Carrito');
      expect(servicio.ultimaCantidad, 2);
      expect(servicio.carrito.cantidadProductos, 3);
      expect(find.byType(DetalleProductoScreen), findsOneWidget);
      await pulsar(tester, 'Ir al carrito');
      expect(find.text('Subtotal (3 productos)'), findsOneWidget);
      await pulsar(tester, 'Volver');
      expect(find.byType(DetalleProductoScreen), findsOneWidget);
      await pulsar(tester, 'Volver');
      expect(find.byType(ListarProductosScreen), findsOneWidget);
      await pulsar(tester, 'Ver carrito');
      await pulsar(tester, 'Seguir comprando');
      expect(
        find.byType(ListarProductosScreen, skipOffstage: false),
        findsOneWidget,
      );
      await pulsar(tester, 'Volver');
      expect(find.byType(ClienteHomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Más, menos y eliminar persisten y actualizan total; mínimo uno',
    (tester) async {
      final ServicioFlujoPrueba servicio = ServicioFlujoPrueba();
      servicio.establecerCantidad(1);
      await tester.pumpWidget(
        FarmayopinApp(
          home: VerCarritoScreen(
            controlador: ControladorCliente(servicio: servicio),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Disminuir cantidad',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byTooltip('Aumentar cantidad'));
      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pumpAndSettle();
      expect(find.text(r'$5.600'), findsOneWidget);
      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.pumpAndSettle();
      expect(find.text(r'$3.150'), findsOneWidget);
      await tester.tap(find.byTooltip('Eliminar producto'));
      await tester.pumpAndSettle();
      expect(find.text('Tu carrito está vacío.'), findsOneWidget);
      expect(find.text('Pagar carrito'), findsNothing);
    },
  );

  testWidgets(
    'Pagar solo navega; método obligatorio, volver y confirmación única vacían carrito',
    (tester) async {
      final ServicioFlujoPrueba servicio = ServicioFlujoPrueba();
      servicio.establecerCantidad(2);
      await tester.pumpWidget(
        FarmayopinApp(
          home: VerCarritoScreen(
            controlador: ControladorCliente(servicio: servicio),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, 'Pagar carrito');
      expect(find.byType(ConfirmarCompraScreen), findsOneWidget);
      expect(servicio.confirmaciones, 0);
      expect(find.text(r'$5.600'), findsOneWidget);
      await pulsar(tester, 'Confirmar pago');
      expect(find.text('Seleccioná un método de pago.'), findsOneWidget);
      expect(servicio.confirmaciones, 0);
      await pulsar(tester, 'Volver al carrito');
      expect(find.byType(VerCarritoScreen), findsOneWidget);
      await pulsar(tester, 'Pagar carrito');
      await pulsar(tester, 'Volver');
      expect(find.byType(VerCarritoScreen), findsOneWidget);
      await pulsar(tester, 'Pagar carrito');
      await pulsar(tester, 'Tarjeta');
      await pulsar(tester, 'Efectivo');
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      final Completer<CompraConfirmada> resultado =
          Completer<CompraConfirmada>();
      servicio.confirmacionDemorada = resultado.future;
      await tester.ensureVisible(find.text('Confirmar pago'));
      await tester.tap(find.text('Confirmar pago'));
      await tester.pump();
      final Finder confirmar = find.widgetWithText(
        FilledButton,
        'Confirmando...',
      );
      expect(tester.widget<FilledButton>(confirmar).onPressed, isNull);
      expect(servicio.confirmaciones, 1);
      resultado.complete(const CompraConfirmada(1, 4900, 700, 5600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Pago realizado'), findsOneWidget);
      expect(find.text('Compra #1 confirmada correctamente.'), findsOneWidget);
      await pulsar(tester, 'Aceptar');
      expect(find.byType(VerCarritoScreen), findsOneWidget);
      expect(find.text('Tu carrito está vacío.'), findsOneWidget);
      expect(servicio.confirmaciones, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Detalle sin stock desactiva agregar y confirmación vacía desactiva pago',
    (tester) async {
      await tester.pumpWidget(
        const FarmayopinApp(
          home: DetalleProductoScreen(
            producto: vitaminaPrueba,
            esCliente: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Agregar al Carrito'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Aumentar cantidad',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(
        const FarmayopinApp(
          home: ConfirmarCompraScreen(
            controlador: ControladorCliente(
              servicio: ServicioClientePrueba(carrito: carritoVacio),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tu carrito está vacío.'), findsOneWidget);
      expect(find.text('Confirmar pago'), findsNothing);
    },
  );

  testWidgets(
    'Detalle y confirmación se adaptan al ancho móvil y texto ampliado',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final double ancho in [320.0, 335.0, 1200.0]) {
        tester.view.physicalSize = Size(ancho, 1000);
        for (final Widget pantalla in [
          const DetalleProductoScreen(
            producto: medicamentoPrueba,
            esCliente: true,
          ),
          const ConfirmarCompraScreen(
            controlador: ControladorCliente(servicio: ServicioClientePrueba()),
          ),
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
    },
  );
}
