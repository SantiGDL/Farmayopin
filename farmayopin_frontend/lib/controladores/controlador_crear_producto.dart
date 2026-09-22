import 'package:flutter/material.dart';

import '../dtos/crear_producto.dart';
import '../dtos/resultado_crear_producto.dart';
import '../widgets/alerta_dialog.dart';
import 'controlador_formulario_producto.dart';

class ControladorCrearProducto extends ControladorFormularioProducto {
  ControladorCrearProducto({super.servicio, super.elegirArchivo});

  Future<void> guardarProducto(BuildContext context) async {
    if (ocupado) return;
    final FormState? formulario = formKey.currentState;
    if (formulario == null) return;
    final bool formularioValido = formulario.validate();
    if (!formularioValido) return;

    ocupado = true;
    progreso = 'Guardando producto…';
    notifyListeners();
    try {
      final bool fotoPreparada = await prepararFoto(context);
      if (!fotoPreparada || cerrado || !context.mounted) return;

      // Paso 2: enviamos JSON con los datos y la ruta relativa (o null).
      progreso = 'Guardando producto…';
      notifyListeners();
      final double precioNumerico = double.parse(
        precio.text.trim().replaceAll(',', '.'),
      );
      final int stockNumerico = int.parse(stock.text.trim());
      final CrearProducto producto = CrearProducto(
        codigo.text.trim(),
        nombre.text.trim(),
        detalle.text.trim(),
        precioNumerico,
        stockNumerico,
        categoria!,
        fotoUrl,
      );
      final ResultadoCrearProducto resultado = await servicio.crearProducto(
        producto,
      );
      if (cerrado || !context.mounted) return;
      String titulo = 'No se pudo crear el producto';
      if (resultado.exito) titulo = 'Producto creado';
      await AlertaDialog.mostrar(
        context,
        titulo,
        resultado.mensaje,
        resultado.exito,
      );
      if (cerrado || !context.mounted) return;
      if (resultado.exito) Navigator.of(context).pop(true);
      // Si falló, conservamos los campos y fotoUrl para reintentar.
    } finally {
      terminarOperacion();
    }
  }
}
