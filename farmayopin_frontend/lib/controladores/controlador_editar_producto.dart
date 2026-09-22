import 'package:flutter/material.dart';

import '../dtos/editar_producto.dart';
import '../dtos/producto_listado.dart';
import '../dtos/resultado_editar_producto.dart';
import '../widgets/alerta_dialog.dart';
import 'controlador_admin.dart';
import 'controlador_formulario_producto.dart';

class ControladorEditarProducto extends ControladorFormularioProducto {
  ControladorEditarProducto({
    super.servicio,
    ProductoListado? producto,
    super.elegirArchivo,
  }) {
    if (producto != null) cargarProducto(producto);
  }

  ProductoListado? producto;

  void cargarProducto(ProductoListado seleccionado) {
    if (ocupado) return;
    producto = seleccionado;
    codigo.text = seleccionado.codigo;
    nombre.text = seleccionado.nombre;
    precio.text = seleccionado.precio.toStringAsFixed(2);
    stock.text = seleccionado.stock.toString();
    detalle.text = seleccionado.descripcion;
    categoria = switch (seleccionado.categoria) {
      'Medicamentos' || 'ANALGESICOS' => 0,
      'Higiene' || 'HIGIENE' => 1,
      'Primeros auxilios' || 'PRIMEROS_AUXILIOS' => 2,
      _ => null,
    };
    fotoBytes = null;
    nombreFoto = null;
    fotoUrl = seleccionado.fotoUrl;
    notifyListeners();
  }

  Future<void> seleccionarProducto(BuildContext context) async {
    if (ocupado) return;
    final ProductoListado? seleccionado = await ControladorAdmin(
      servicio: servicio,
    ).seleccionarProductoEdicion(context);
    if (cerrado || !context.mounted || seleccionado == null) return;
    cargarProducto(seleccionado);
  }

  @override
  Future<void> seleccionarFoto(BuildContext context) async {
    if (producto == null) return;
    await super.seleccionarFoto(context);
  }

  // Los productos antiguos pueden no tener categoría. Editar otro campo no
  // obliga a asignar una; las categorías elegidas siempre salen del catálogo.
  @override
  String? validarCategoria(int? valor) => null;

  Future<void> guardarProducto(BuildContext context) async {
    final ProductoListado? original = producto;
    if (ocupado || original == null) return;
    final FormState? formulario = formKey.currentState;
    if (formulario == null || !formulario.validate()) return;
    ocupado = true;
    progreso = 'Guardando cambios…';
    notifyListeners();
    try {
      final bool fotoPreparada = await prepararFoto(context);
      if (!fotoPreparada || cerrado || !context.mounted) return;
      progreso = 'Guardando cambios…';
      notifyListeners();
      final EditarProducto cambios = EditarProducto(
        original.codigo,
        nombre.text.trim(),
        detalle.text.trim(),
        double.parse(precio.text.trim().replaceAll(',', '.')),
        int.parse(stock.text.trim()),
        categoria,
        fotoUrl,
      );
      final ResultadoEditarProducto resultado = await servicio.editarProducto(
        cambios,
      );
      if (cerrado || !context.mounted) return;
      await AlertaDialog.mostrar(
        context,
        resultado.exito ? 'Producto editado' : 'No se pudo editar el producto',
        resultado.mensaje,
        resultado.exito,
      );
      if (cerrado || !context.mounted || !resultado.exito) return;
      final String? categoriaBackend = switch (categoria) {
        0 => 'ANALGESICOS',
        1 => 'HIGIENE',
        2 => 'PRIMEROS_AUXILIOS',
        _ => null,
      };
      Navigator.of(context).pop(
        ProductoListado(
          cambios.nombre,
          cambios.detalle,
          cambios.precio,
          cambios.stock,
          ProductoListado.nombreCategoria(categoriaBackend),
          id: original.id,
          codigo: original.codigo,
          fotoUrl: cambios.fotoUrl,
          unidad: original.unidad,
        ),
      );
    } finally {
      terminarOperacion();
    }
  }
}
