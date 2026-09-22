import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/controladores/controlador_crear_producto.dart';
import 'package:farmayopin_frontend/dtos/crear_producto.dart';
import 'package:farmayopin_frontend/dtos/resultado_crear_producto.dart';
import 'package:farmayopin_frontend/dtos/resultado_subir_foto.dart';
import 'package:farmayopin_frontend/screens/crear_producto_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_admin.dart';

final Uint8List png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
);

class ServicioPrueba extends ServicioAdmin {
  int subidas = 0;
  final List<CrearProducto> productos = [];
  bool fallaFoto = false;
  bool fallaCreacion = false;
  Completer<ResultadoCrearProducto>? pendiente;

  @override
  Future<ResultadoSubirFoto> subirFoto(Uint8List bytes, String nombre) async {
    subidas++;
    if (fallaFoto) {
      return const ResultadoSubirFoto(false, 'Error de subida', null);
    }
    return const ResultadoSubirFoto(
      true,
      'OK',
      '/Imagenes/Productos/prueba.png',
    );
  }

  @override
  Future<ResultadoCrearProducto> crearProducto(CrearProducto producto) async {
    productos.add(producto);
    if (pendiente != null) return pendiente!.future;
    if (fallaCreacion) {
      return const ResultadoCrearProducto(false, 'Código repetido');
    }
    return const ResultadoCrearProducto(
      true,
      'Producto registrado correctamente.',
    );
  }
}

Future<ControladorCrearProducto> abrir(
  WidgetTester tester,
  ServicioPrueba servicio, {
  Future<XFile?> Function()? selector,
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controlador = ControladorCrearProducto(
    servicio: servicio,
    elegirArchivo:
        selector ??
        () async {
          return XFile.fromData(png, name: 'foto.png', path: 'foto.png');
        },
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return CrearProductoScreen(controlador: controlador);
                    },
                  ),
                );
              },
              child: const Text('Abrir formulario'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Abrir formulario'));
  await tester.pumpAndSettle();
  return controlador;
}

Future<void> completar(WidgetTester tester) async {
  final campos = find.byType(TextFormField);
  await tester.enterText(campos.at(0), 'P-123');
  await tester.enterText(campos.at(1), 'Jabón');
  await tester.enterText(campos.at(2), '12,50');
  await tester.enterText(campos.at(3), '3');
  await tester.enterText(campos.at(4), 'Descripción');
  final selector = find.byType(DropdownButtonFormField<int>);
  await tester.ensureVisible(selector);
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Higiene personal').last);
  await tester.pumpAndSettle();
}

Future<void> guardar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Guardar producto'));
  await tester.tap(find.text('Guardar producto'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Servicio envía el contrato JSON y acepta solo 201 como creación',
    () async {
      final cliente = MockClient((peticion) async {
        expect(peticion.method, 'POST');
        expect(peticion.url.path, '/api/controladorAdmin/crearProducto');
        expect(jsonDecode(peticion.body), {
          'codigo': 'P1',
          'nombre': 'Jabón',
          'detalle': 'D',
          'precio': 12.5,
          'stock': 3,
          'categoria': 1,
          'fotoUrl': null,
        });
        return http.Response('{}', 201);
      });
      addTearDown(cliente.close);
      final servicio = ServicioAdmin(cliente: cliente);
      final resultado = await servicio.crearProducto(
        const CrearProducto('P1', 'Jabón', 'D', 12.5, 3, 1, null),
      );
      expect(resultado.exito, isTrue);
    },
  );

  test(
    'Servicio sube bytes multipart y obtiene la ruta del servidor',
    () async {
      final cliente = MockClient((peticion) async {
        expect(peticion.url.path, '/api/controladorAdmin/subirFoto');
        expect(
          peticion.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        final cuerpo = latin1.decode(peticion.bodyBytes);
        expect(cuerpo, contains('name="foto"; filename="foto.png"'));
        expect(cuerpo, contains(latin1.decode(png)));
        return http.Response('{"fotoUrl":"/Imagenes/Productos/abc.png"}', 201);
      });
      addTearDown(cliente.close);
      final resultado = await ServicioAdmin(cliente: cliente)
          .subirFoto(png, 'foto.png');
      expect(resultado.fotoUrl, '/Imagenes/Productos/abc.png');
      expect(resultado.exito, isTrue);
    },
  );

  test(
    'Servicio comunica conflictos, errores de validación y fallos de conexión',
    () async {
      const producto = CrearProducto('P1', 'Jabón', '', 0, 0, 1, null);
      for (final respuesta in [
        http.Response(
          '{"mensaje":"Código repetido"}',
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
        http.Response('{"errors":{"Nombre":["Falta el nombre"]}}', 400),
        http.Response('<html>Error</html>', 500),
      ]) {
        final cliente = MockClient((_) async {
          return respuesta;
        });
        final resultado = await ServicioAdmin(cliente: cliente)
            .crearProducto(producto);
        expect(resultado.exito, isFalse);
        expect(resultado.mensaje, isNotEmpty);
        cliente.close();
      }
      final cliente = MockClient((_) async {
        throw http.ClientException('sin red');
      });
      expect(
        (await ServicioAdmin(cliente: cliente).crearProducto(producto)).exito,
        isFalse,
      );
      cliente.close();
    },
  );

  testWidgets('Valida antes de llamar al backend y crea sin foto', (
    tester,
  ) async {
    final servicio = ServicioPrueba();
    await abrir(tester, servicio);
    await guardar(tester);
    expect(servicio.productos, isEmpty);
    await completar(tester);
    await guardar(tester);
    expect(servicio.subidas, 0);
    expect(servicio.productos.single.fotoUrl, isNull);
    expect(servicio.productos.single.precio, 12.5);
    expect(servicio.productos.single.categoria, 1);
    expect(find.text('Producto creado'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(find.byType(CrearProductoScreen), findsNothing);
  });

  testWidgets(
    'Sube una vez y conserva datos y ruta al reintentar la creación',
    (tester) async {
      final servicio = ServicioPrueba()..fallaCreacion = true;
      final controlador = await abrir(tester, servicio);
      await completar(tester);
      await tester.ensureVisible(
        find.text('Seleccioná una foto del producto (opcional)'),
      );
      await tester.tap(
        find.text('Seleccioná una foto del producto (opcional)'),
      );
      await tester.pumpAndSettle();
      expect(find.text('foto.png'), findsOneWidget);
      await guardar(tester);
      expect(servicio.subidas, 1);
      expect(
        servicio.productos.single.fotoUrl,
        '/Imagenes/Productos/prueba.png',
      );
      expect(find.text('Código repetido'), findsOneWidget);
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(controlador.nombre.text, 'Jabón');
      servicio.fallaCreacion = false;
      await guardar(tester);
      expect(servicio.subidas, 1);
      expect(servicio.productos.length, 2);
    },
  );

  testWidgets('Si falla la subida no crea el producto', (tester) async {
    final servicio = ServicioPrueba()..fallaFoto = true;
    final controlador = await abrir(tester, servicio);
    await completar(tester);
    controlador.fotoBytes = png;
    controlador.nombreFoto = 'foto.png';
    await guardar(tester);
    expect(servicio.productos, isEmpty);
    expect(find.text('Error de subida'), findsOneWidget);
  });

  testWidgets(
    'Bloquea doble envío y descarta respuestas al cerrar la pantalla',
    (tester) async {
      final servicio = ServicioPrueba()
        ..pendiente = Completer<ResultadoCrearProducto>();
      final controlador = await abrir(tester, servicio);
      await completar(tester);
      await guardar(tester);
      expect(find.text('Guardando producto…'), findsOneWidget);
      final context = tester.element(find.byType(CrearProductoScreen));
      await controlador.guardarProducto(context);
      expect(servicio.productos.length, 1);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      servicio.pendiente!.complete(const ResultadoCrearProducto(true, 'OK'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cancelar selector no agrega foto; quitar permite guardar sin ella',
    (tester) async {
      final servicio = ServicioPrueba();
      final controlador = await abrir(
        tester,
        servicio,
        selector: () async {
          return null;
        },
      );
      final context = tester.element(find.byType(CrearProductoScreen));
      await controlador.seleccionarFoto(context);
      expect(controlador.fotoBytes, isNull);
      controlador.fotoBytes = png;
      controlador.nombreFoto = 'foto.png';
      controlador.quitarFoto();
      await completar(tester);
      await guardar(tester);
      expect(servicio.subidas, 0);
      expect(servicio.productos.single.fotoUrl, isNull);
    },
  );
}
