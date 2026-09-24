import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/controladores/controlador_admin.dart';
import 'package:farmayopin_frontend/controladores/controlador_editar_producto.dart';
import 'package:farmayopin_frontend/dtos/editar_producto.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
import 'package:farmayopin_frontend/dtos/resultado_editar_producto.dart';
import 'package:farmayopin_frontend/dtos/resultado_subir_foto.dart';
import 'package:farmayopin_frontend/main.dart';
import 'package:farmayopin_frontend/screens/admin_home_screen.dart';
import 'package:farmayopin_frontend/screens/editar_producto_screen.dart';
import 'package:farmayopin_frontend/screens/listar_productos_screen.dart';
import 'package:farmayopin_frontend/servicios/servicio_admin.dart';

const original = ProductoListado(
  'Jabón',
  'Descripción original',
  1250.50,
  35,
  'Higiene',
  id: 42,
  codigo: 'SKU-ABC',
  fotoUrl: '/Imagenes/Productos/original.png',
  unidad: 'UNIDAD',
);

class ServicioEdicionPrueba extends ServicioAdmin {
  @override
  Future<Map<int, String>> listarCategorias() async => {0: 'Medicamentos', 1: 'Higiene', 3: 'Vitaminas', 4: 'Sin categoría'};
  ProductoListado actual = original;
  final List<EditarProducto> cambios = [];
  int subidas = 0;
  bool falla = false;
  bool fallaFoto = false;
  Completer<ResultadoEditarProducto>? pendiente;

  @override
  Future<List<ProductoListado>> listarProductos() async => [actual];

  @override
  Future<ResultadoSubirFoto> subirFoto(Uint8List bytes, String nombre) async {
    subidas++;
    if (fallaFoto) {
      return const ResultadoSubirFoto(false, 'Falló la foto', null);
    }
    return const ResultadoSubirFoto(
      true,
      'OK',
      '/Imagenes/Productos/nueva.png',
    );
  }

  @override
  Future<ResultadoEditarProducto> editarProducto(
    EditarProducto producto,
  ) async {
    cambios.add(producto);
    if (pendiente != null) return pendiente!.future;
    if (falla) return const ResultadoEditarProducto(false, 'Error al guardar');
    actual = ProductoListado(
      producto.nombre,
      producto.detalle,
      producto.precio,
      producto.stock,
      'Higiene',
      id: original.id,
      codigo: producto.codigo,
      fotoUrl: producto.fotoUrl,
    );
    return const ResultadoEditarProducto(true, 'Cambios guardados');
  }
}

Future<void> tocar(WidgetTester tester, String texto) async {
  final encontrado = find.text(texto);
  await tester.ensureVisible(encontrado);
  await tester.tap(encontrado);
  await tester.pumpAndSettle();
}

void pantallaGrande(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(600, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  test('Actualización usa PUT y el código original, conserva la foto y no crea otro endpoint', () async {
    final servicio = ServicioAdmin(
      cliente: MockClient((peticion) async {
        expect(peticion.method, 'PUT');
        expect(peticion.url.path, '/api/controladorAdmin/editarProducto');
        expect(jsonDecode(peticion.body), {
          'codigo': 'SKU-ABC',
          'nombre': 'Nuevo',
          'detalle': 'D',
          'precio': 12.50,
          'stock': 4,
          'categoria': 2,
          'fotoUrl': original.fotoUrl,
        });
        return http.Response('{}', 200);
      }),
    );
    expect(
      (await servicio.editarProducto(
        EditarProducto('SKU-ABC', 'Nuevo', 'D', 12.50, 4, 2, original.fotoUrl),
      )).exito,
      isTrue,
    );
  });

  test('Errores de API y de conexión no informan éxito', () async {
    for (final codigo in [400, 404, 500]) {
      final servicio = ServicioAdmin(
        cliente: MockClient(
          (_) async => http.Response('{"mensaje":"No guardado"}', codigo),
        ),
      );
      final resultado = await servicio.editarProducto(
        const EditarProducto('A', 'N', '', 0, 0, null, null),
      );
      expect(resultado.exito, isFalse);
      expect(resultado.mensaje, 'No guardado');
    }
    final servicio = ServicioAdmin(
      cliente: MockClient((_) async => throw http.ClientException('Sin red')),
    );
    expect(
      (await servicio.editarProducto(
        const EditarProducto('A', 'N', '', 0, 0, null, null),
      )).exito,
      isFalse,
    );
  });

  testWidgets(
    'Panel abre vacío, bloquea acciones, permite cancelar selección y luego editar',
    (tester) async {
      pantallaGrande(tester);
      final servicio = ServicioEdicionPrueba();
      await tester.pumpWidget(
        FarmayopinApp(
          home: AdminHomeScreen(
            controlador: ControladorAdmin(servicio: servicio),
          ),
        ),
      );
      expect(find.text('Ver producto'), findsNothing);
      await tocar(tester, 'Editar producto');
      expect(find.byType(EditarProductoScreen), findsOneWidget);
      for (final campo in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(campo.enabled, isFalse);
        expect(campo.controller!.text, isEmpty);
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Guardar cambios'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cambiar foto'))
            .onPressed,
        isNull,
      );
      await tocar(tester, 'SELECCIONE PRODUCTO');
      expect(find.text('Ver'), findsNothing);
      expect(find.text('Editar'), findsNothing);
      await tocar(tester, 'Volver');
      expect(find.text('SELECCIONE PRODUCTO'), findsOneWidget);
      await tocar(tester, 'SELECCIONE PRODUCTO');
      await tester.enterText(find.byType(TextField), 'Jab');
      await tester.pumpAndSettle();
      await tocar(tester, 'Jabón');
      expect(find.byType(ListarProductosScreen), findsNothing);
      final campos = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(campos.at(0)).controller!.text,
        'Jabón',
      );
      expect(
        tester.widget<TextFormField>(campos.at(1)).controller!.text,
        '1250.50',
      );
      expect(tester.widget<TextFormField>(campos.at(2)).controller!.text, '35');
      expect(find.text('Higiene'), findsOneWidget);
      await tester.enterText(campos.at(0), 'Jabón nuevo');
      await tester.enterText(campos.at(1), '1500,25');
      await tocar(tester, 'Guardar cambios');
      expect(servicio.cambios.single.codigo, 'SKU-ABC');
      expect(servicio.cambios.single.precio, 1500.25);
      expect(servicio.cambios.single.fotoUrl, original.fotoUrl);
      expect(servicio.subidas, 0);
      await tocar(tester, 'Aceptar');
      expect(find.byType(AdminHomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Editar desde listado precarga y actualiza el listado al guardar',
    (tester) async {
      pantallaGrande(tester);
      final servicio = ServicioEdicionPrueba();
      await tester.pumpWidget(
        FarmayopinApp(
          home: ListarProductosScreen(
            controladorAdmin: ControladorAdmin(servicio: servicio),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ver'), findsOneWidget);
      await tocar(tester, 'Editar');
      expect(find.text('SELECCIONE PRODUCTO'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Nombre editado',
      );
      await tocar(tester, 'Guardar cambios');
      await tocar(tester, 'Aceptar');
      expect(find.text('Nombre editado'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Valida campos, sube foto una vez y conserva cambios tras error',
    (tester) async {
      pantallaGrande(tester);
      final servicio = ServicioEdicionPrueba();
      servicio.falla = true;
      final Uint8List png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      );
      final controlador = ControladorEditarProducto(
        servicio: servicio,
        producto: original,
        elegirArchivo: () async => XFile.fromData(png, name: 'nueva.png'),
      );
      await tester.pumpWidget(
        FarmayopinApp(home: EditarProductoScreen(controlador: controlador)),
      );
      await tester.enterText(find.byType(TextFormField).at(1), '-1');
      await tocar(tester, 'Guardar cambios');
      expect(servicio.cambios, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(1), '20,50');
      await tocar(tester, 'Cambiar foto');
      servicio.fallaFoto = true;
      await tocar(tester, 'Guardar cambios');
      expect(servicio.cambios, isEmpty);
      await tocar(tester, 'Aceptar');
      servicio.fallaFoto = false;
      await tocar(tester, 'Guardar cambios');
      expect(servicio.subidas, 2);
      expect(servicio.cambios.single.fotoUrl, '/Imagenes/Productos/nueva.png');
      await tocar(tester, 'Aceptar');
      expect(controlador.precio.text, '20,50');
      await tocar(tester, 'Guardar cambios');
      expect(servicio.subidas, 2);
      expect(servicio.cambios.length, 2);
    },
  );

  testWidgets('Bloquea doble envío y no usa respuestas después de dispose', (
    tester,
  ) async {
    pantallaGrande(tester);
    final servicio = ServicioEdicionPrueba();
    servicio.pendiente = Completer<ResultadoEditarProducto>();
    final controlador = ControladorEditarProducto(
      servicio: servicio,
      producto: original,
    );
    await tester.pumpWidget(
      FarmayopinApp(home: EditarProductoScreen(controlador: controlador)),
    );
    await tocar(tester, 'Guardar cambios');
    final context = tester.element(find.byType(EditarProductoScreen));
    await controlador.guardarProducto(context);
    expect(servicio.cambios.length, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    servicio.pendiente!.complete(const ResultadoEditarProducto(true, 'OK'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Formulario vacío y cargado se adaptan a móvil con texto ampliado',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final ancho in [320.0, 412.0, 1200.0]) {
        tester.view.physicalSize = Size(ancho, 1000);
        for (final producto in [null, original]) {
          await tester.pumpWidget(
            FarmayopinApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: EditarProductoScreen(
                  key: UniqueKey(),
                  producto: producto,
                ),
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
