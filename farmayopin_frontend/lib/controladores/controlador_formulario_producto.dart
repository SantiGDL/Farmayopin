import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../dtos/resultado_subir_foto.dart';
import '../servicios/servicio_admin.dart';
import '../widgets/alerta_dialog.dart';

// Estado propio de este formulario administrativo. El panel y el listado
// siguen usando ControladorAdmin sin cargar campos que no necesitan.
abstract class ControladorFormularioProducto extends ChangeNotifier {
  ControladorFormularioProducto({
    this.servicio = const ServicioAdmin(),
    Future<XFile?> Function()? elegirArchivo,
  }) : _elegirArchivo = elegirArchivo ?? _abrirSelector {
    cargarCategorias();
  }

  Map<int, String> categorias = {};
  bool cargandoCategorias = true;
  String? errorCategorias;
  String? nombreCategoriaActual;

  void resolverCategoriaActual() {
    if (nombreCategoriaActual == null) return;
    categoria = null;
    for (final entrada in categorias.entries) {
      if (entrada.value == nombreCategoriaActual) categoria = entrada.key;
    }
  }

  Future<void> cargarCategorias() async {
    cargandoCategorias = true;
    errorCategorias = null;
    notifyListeners();
    try {
      final recibidas = await servicio.listarCategorias();
      if (cerrado) return;
      categorias = recibidas;
      resolverCategoriaActual();
    } catch (_) {
      if (cerrado) return;
      errorCategorias = 'No se pudieron cargar las categorías.';
    } finally {
      if (!cerrado) {
        cargandoCategorias = false;
        notifyListeners();
      }
    }
  }

  final ServicioAdmin servicio;
  final Future<XFile?> Function() _elegirArchivo;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codigo = TextEditingController();
  final TextEditingController nombre = TextEditingController();
  final TextEditingController precio = TextEditingController();
  final TextEditingController stock = TextEditingController();
  final TextEditingController detalle = TextEditingController();
  int? categoria;
  Uint8List? fotoBytes;
  String? nombreFoto;
  String? fotoUrl;
  bool ocupado = false;
  String progreso = '';
  bool cerrado = false;

  static Future<XFile?> _abrirSelector() {
    const XTypeGroup imagenes = XTypeGroup(
      label: 'JPG o PNG',
      extensions: ['jpg', 'jpeg', 'png'],
      mimeTypes: ['image/jpeg', 'image/png'],
      uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
    );
    return openFile(acceptedTypeGroups: [imagenes]);
  }

  String? validarObligatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Completá este campo.';
    return null;
  }

  String? validarPrecio(String? valor) {
    final String texto = valor?.trim() ?? '';
    if (!RegExp(r'^\d{1,12}([.,]\d{1,2})?$').hasMatch(texto)) {
      return 'Usá un precio positivo o cero, con hasta 2 decimales y 12 dígitos enteros.';
    }
    return null;
  }

  String? validarStock(String? valor) {
    final String texto = valor?.trim() ?? '';
    final int? cantidad = int.tryParse(texto);
    if (!RegExp(r'^\d+$').hasMatch(texto) ||
        cantidad == null ||
        cantidad > 2147483647) {
      return 'Usá un entero entre 0 y 2147483647.';
    }
    return null;
  }

  String? validarCategoria(int? valor) {
    if (valor == null || !categorias.containsKey(valor)) return 'Seleccioná una categoría.';
    return null;
  }

  void cambiarCategoria(int? valor) {
    categoria = valor;
  }

  Future<void> seleccionarFoto(BuildContext context) async {
    if (ocupado) return;
    ocupado = true;
    progreso = 'Seleccionando foto…';
    notifyListeners();
    try {
      final XFile? archivo = await _elegirArchivo();
      if (cerrado || !context.mounted || archivo == null) return;
      final int tamano = await archivo.length();
      if (cerrado || !context.mounted) return;
      if (tamano == 0 || tamano > 5 * 1024 * 1024) {
        await AlertaDialog.mostrar(
          context,
          'Revisá la foto',
          'Elegí una imagen JPG o PNG de hasta 5 MB que no esté vacía.',
          false,
        );
        return;
      }
      final Uint8List bytes = await archivo.readAsBytes();
      if (cerrado || !context.mounted) return;
      // El filtro del selector no sustituye la comprobación del backend.
      final bool jpg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      const List<int> firmaPng = [137, 80, 78, 71, 13, 10, 26, 10];
      bool png = bytes.length >= firmaPng.length;
      if (png) {
        for (int i = 0; i < firmaPng.length; i++) {
          if (bytes[i] != firmaPng[i]) png = false;
        }
      }
      if (!jpg && !png) {
        await AlertaDialog.mostrar(
          context,
          'Revisá la foto',
          'Solo se admiten imágenes JPG o PNG.',
          false,
        );
        return;
      }
      fotoBytes = bytes;
      nombreFoto = archivo.name;
      fotoUrl = null;
    } catch (_) {
      if (!cerrado && context.mounted) {
        await AlertaDialog.mostrar(
          context,
          'No se pudo abrir la foto',
          'Intentá seleccionar el archivo nuevamente.',
          false,
        );
      }
    } finally {
      terminarOperacion();
    }
  }

  void quitarFoto() {
    if (ocupado) return;
    fotoBytes = null;
    nombreFoto = null;
    fotoUrl = null;
    notifyListeners();
  }

  // Creación y edición comparten selección, validación y subida de la foto.
  // Una URL ya subida se conserva para no repetir la subida al reintentar.
  Future<bool> prepararFoto(BuildContext context) async {
    if (fotoBytes == null || fotoUrl != null) return true;
    progreso = 'Subiendo foto…';
    notifyListeners();
    final ResultadoSubirFoto foto = await servicio.subirFoto(
      fotoBytes!,
      nombreFoto!,
    );
    if (cerrado || !context.mounted) return false;
    if (!foto.exito) {
      await AlertaDialog.mostrar(
        context,
        'No se pudo subir la foto',
        foto.mensaje,
        false,
      );
      return false;
    }
    fotoUrl = foto.fotoUrl;
    return true;
  }

  void terminarOperacion() {
    if (cerrado) return;
    ocupado = false;
    progreso = '';
    notifyListeners();
  }

  void cancelar(BuildContext context) {
    if (!ocupado) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    cerrado = true;
    codigo.dispose();
    nombre.dispose();
    precio.dispose();
    stock.dispose();
    detalle.dispose();
    super.dispose();
  }
}
