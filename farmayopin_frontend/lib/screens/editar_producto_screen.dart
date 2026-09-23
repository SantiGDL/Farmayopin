import 'package:flutter/material.dart';

import '../controladores/controlador_admin.dart';
import '../controladores/controlador_editar_producto.dart';
import '../dtos/producto_listado.dart';
import '../widgets/campos_producto.dart';
import '../widgets/encabezado_admin.dart';
import '../widgets/imagen_producto.dart';
import '../widgets/volver_cliente.dart';

// Los dos accesos usan este formulario: el producto inicial es opcional.
// ================== ESTRUCTURA Y LÓGICA ==================

class EditarProductoScreen extends StatefulWidget {
  const EditarProductoScreen({
    super.key,
    this.producto,
    this.controladorAdmin = const ControladorAdmin(),
    this.controlador,
  });
  final ProductoListado? producto;
  final ControladorAdmin controladorAdmin;
  final ControladorEditarProducto? controlador;

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  late final ControladorEditarProducto controlador;

  @override
  void initState() {
    super.initState();
    controlador =
        widget.controlador ??
        ControladorEditarProducto(
          servicio: widget.controladorAdmin.servicio,
          producto: widget.producto,
        );
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
            child: Scaffold(
              body: SafeArea(
                child: _crearContenidoCentrado(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _crearEstructuraPantalla(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EncabezadoAdmin(
          cerrarSesion: () =>
              widget.controladorAdmin.cerrarSesion(context),
        ),
        VolverCliente(
          volver: () => controlador.cancelar(context),
        ),
        _crearPresentacion(),
        const SizedBox(height: 20),
        _crearFormulario(context),
      ],
    );
  }

  Widget _crearFormulario(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(16)),
      child: Form(
        key: controlador.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Foto del producto'),
            const SizedBox(height: 12),
            _crearSelectorFoto(),
            const SizedBox(height: 24),
            CamposProducto(
              controlador: controlador,
              habilitado:
                  controlador.producto != null &&
                  !controlador.ocupado,
              esEdicion: true,
            ),
            const SizedBox(height: 20),
            _crearBotonGuardar(context),
          ],
        ),
      ),
    );
  }

  Widget _crearBotonGuardar(BuildContext context) {
    return FilledButton.icon(
      onPressed:
          controlador.producto == null ||
              controlador.ocupado
          ? null
          : () => controlador.guardarProducto(
              context,
            ),
      icon: const Icon(Icons.save_outlined),
      label: Text(controlador.ocupado ? controlador.progreso : 'Guardar cambios'),
    );
  }

  Widget _crearSelectorFoto() {
    final ProductoListado? producto = controlador.producto;
    final Widget imagen;
    if (producto == null) {
      imagen = FilledButton(
        onPressed: () => controlador.seleccionarProducto(context),
        child: const Text('Seleccione Producto a Editar'),
      );
    } else if (controlador.fotoBytes != null) {
      imagen = Image.memory(
        controlador.fotoBytes!,
        width: 130,
        height: 130,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) =>
            const Text('No se pudo mostrar la vista previa.'),
      );
    } else {
      imagen = ImagenProducto(producto: producto, tamano: 130);
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(width: 180, child: imagen),
        TextButton.icon(
          onPressed: producto == null || controlador.ocupado
              ? null
              : () => controlador.seleccionarFoto(context),
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('Cambiar foto'),
          style: TextButton.styleFrom(backgroundColor: const Color(0xFFB9E8E5)),
        ),
      ],
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _crearEstructuraPantalla(context),
        ),
      ),
    );
  }

  Widget _crearPresentacion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF50BDB5), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Editar producto',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Modifica la información del producto seleccionado.',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Image.asset(
                  'assets/Iconos/IconoAdmin.png',
                  height: 130,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
