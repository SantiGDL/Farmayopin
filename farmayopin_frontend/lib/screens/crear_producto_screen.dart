import '../widgets/campos_producto.dart';
import 'package:flutter/material.dart';

import '../controladores/controlador_crear_producto.dart';
import '../controladores/controlador_general.dart';
import '../widgets/foto_producto_selector.dart';

// La pantalla dibuja el formulario y conecta sus eventos al controlador.
// ================== ESTRUCTURA Y LÓGICA ==================

class CrearProductoScreen extends StatefulWidget {
  const CrearProductoScreen({super.key, this.controlador});
  final ControladorCrearProducto? controlador;

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  late final ControladorCrearProducto controlador;

  @override
  void initState() {
    super.initState();
    controlador = widget.controlador ?? ControladorCrearProducto();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, child) {
        return PopScope(
          canPop: !controlador.ocupado,
          child: AbsorbPointer(
            absorbing: controlador.ocupado,
            child: _crearPantalla(context),
          ),
        );
      },
    );
  }

  Widget _crearPantalla(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Permite desplazar el formulario si la pantalla es pequeña
        // o si el teclado tapa los campos.
        child: _crearContenidoCentrado(context),
      ),
    );
  }

  Widget _crearFormulario(BuildContext context) {
    return Form(
      key: controlador.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _crearEncabezado(context),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => controlador.cancelar(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ),
          const SizedBox(height: 8),
          _crearTarjetaPresentacion(),
          const SizedBox(height: 24),

          _crearCampoTexto(
            etiqueta: 'Código',
            ayuda: 'Ingresá un código único',
            icono: Icons.qr_code,
            campo: controlador.codigo,
            validar: controlador.validarObligatorio,
          ),
          const SizedBox(height: 16),
          CamposProducto(controlador: controlador),
          const SizedBox(height: 16),
          const Text('Foto del producto'),
          const SizedBox(height: 6),
          _crearSelectorFoto(context),
          const SizedBox(height: 20),

          _crearBotonGuardar(context),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => controlador.cancelar(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _crearBotonGuardar(BuildContext context) {
    return FilledButton.icon(
      onPressed: controlador.ocupado
          ? null
          : () => controlador.guardarProducto(context),
      icon: const Icon(Icons.save_outlined),
      label: Text(controlador.ocupado ? controlador.progreso : 'Guardar producto'),
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Reúne la etiqueta, el campo y su validación.
  Widget _crearCampoTexto({
    required String etiqueta,
    required String ayuda,
    required IconData icono,
    required TextEditingController campo,
    String? Function(String?)? validar,
    int lineas = 1,
    TextInputType teclado = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta),
        const SizedBox(height: 6),
        TextFormField(
          controller: campo,
          validator: validar,
          maxLines: lineas,
          keyboardType: teclado,
          style: const TextStyle(fontSize: 14),
          decoration: _crearDecoracionCampo(ayuda, icono),
        ),
      ],
    );
  }

  Widget _crearSelectorFoto(BuildContext context) {
    return FotoProductoSelector(
      bytes: controlador.fotoBytes,
      nombre: controlador.nombreFoto,
      seleccionar: controlador.ocupado
          ? null
          : () => controlador.seleccionarFoto(context),
      quitar: controlador.ocupado ? null : controlador.quitarFoto,
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        // Equivale a un max-width de CSS. En celular ocupa lo disponible.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _crearFormulario(context),
        ),
      ),
    );
  }

  Widget _crearEncabezado(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/farmayopin_logo.png', width: 100),
            const Text('Administrador', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        TextButton.icon(
          onPressed: () => ControladorGeneral.cerrarSesion(context),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: const Color(0xFFF2F2F2),
          ),
        ),
      ],
    );
  }

  Widget _crearTarjetaPresentacion() {
    // Container combina fondo, bordes y espacio: parecido a un div con CSS.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF4BC3B5), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear producto',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Agregá nuevos artículos al inventario de la farmacia.',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.medication, size: 90, color: Color(0xFF9AE5D4)),
        ],
      ),
    );
  }

  // Estilo compartido de los inputs; los bordes se heredan de main.dart.
  InputDecoration _crearDecoracionCampo(String ayuda, IconData icono) {
    return InputDecoration(
      hintText: ayuda,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icono, size: 20, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
