import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmayopin_frontend/servicios/servicio_general.dart';

void main() {
  test('Login conserva el rol y recibe el token para consultar el carrito', () async {
    final servicio = ServicioGeneral(cliente: MockClient((request) async {
      expect(request.url.path, '/api/controladorGeneral/consultarRolUsuario');
      return http.Response('{"rol":"Cliente","token":"token-cliente"}', 200);
    }));
    addTearDown(servicio.dispose);
    final resultado = await servicio.iniciarSesion('ana@example.com', 'prueba123');
    expect(resultado.exito, isTrue);
    expect(resultado.rol, 'Cliente');
    expect(resultado.token, 'token-cliente');
  });

  test('Registro envía el contrato del backend y acepta 200 y 201', () async {
    for (final status in [200, 201]) {
      final servicio = ServicioGeneral(
        cliente: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'http://localhost:5206/api/controladorGeneral/nuevoCliente',
          );
          expect(jsonDecode(request.body), {
            'Nombre': 'Ana',
            'Correo': 'ana@correo.com',
            'Pass': ' secreto ',
            'Imagen': '',
          });
          return http.Response('', status);
        }),
      );
      final resultado = await servicio.registrarCliente(
        ' Ana ',
        ' ana@correo.com ',
        ' secreto ',
      );
      expect(resultado.exito, isTrue);
      servicio.dispose();
    }
  });

  test('Registro interpreta errores JSON, texto y respuestas vacías', () async {
    final casos = {
      '{"mensaje":"Correo duplicado"}': 'Correo duplicado',
      'Error del servidor': 'Error del servidor',
      '': 'No se pudo registrar el usuario.',
      '{"mensaje":42}': 'No se pudo registrar el usuario.',
    };
    for (final caso in casos.entries) {
      final servicio = ServicioGeneral(
        cliente: MockClient((_) async => http.Response(caso.key, 409)),
      );
      final resultado = await servicio.registrarCliente(
        'Ana',
        'a@b.com',
        '123456',
      );
      expect(resultado.exito, isFalse);
      expect(resultado.mensaje, caso.value);
      servicio.dispose();
    }
  });

  test('Registro informa un fallo de conexión', () async {
    final servicio = ServicioGeneral(
      cliente: MockClient((_) async => throw http.ClientException('Sin red')),
    );
    final resultado = await servicio.registrarCliente(
      'Ana',
      'a@b.com',
      '123456',
    );
    expect(resultado.exito, isFalse);
    expect(resultado.mensaje, contains('No se pudo conectar'));
    servicio.dispose();
  });
}
