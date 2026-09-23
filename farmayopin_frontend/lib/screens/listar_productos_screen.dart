import '../widgets/encabezado_admin.dart';
import '../widgets/encabezado_cliente.dart';
import '../widgets/presentacion_cliente.dart';
import '../widgets/buscador_productos.dart';
import '../widgets/filtros_productos.dart';
import '../widgets/tarjeta_producto_cliente.dart';
import 'package:flutter/material.dart';

import '../controladores/controlador_admin.dart';
import '../dtos/producto_listado.dart';
import '../config/api_config.dart';
import '../controladores/controlador_cliente.dart';

// ================== ESTRUCTURA Y LÓGICA ==================

class ListarProductosScreen extends StatefulWidget {
  const ListarProductosScreen({
    super.key,
    this.esCliente = false,
    this.seleccionarParaHistorial = false,
    this.seleccionarParaEdicion = false,
    this.controladorAdmin = const ControladorAdmin(),
    this.controladorCliente = const ControladorCliente(),
  });

  final bool esCliente;
  final bool seleccionarParaHistorial;
  final bool seleccionarParaEdicion;
  final ControladorAdmin controladorAdmin;
  final ControladorCliente controladorCliente;

  @override
  State<ListarProductosScreen> createState() {
    return _ListarProductosScreenState();
  }
}

class _ListarProductosScreenState extends State<ListarProductosScreen> {
  ControladorAdmin get controladorAdmin => widget.controladorAdmin;
  List<ProductoListado> productos = [];
  bool cargando = true;
  bool agregando = false;
  String? errorCarga;
  String busqueda = '';
  String categoria = 'Todos';
  static const Color turquesa = Color(0xFF50BDB5);
  static const String iconos = 'assets/Iconos';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  //Metodo para Cargar la lista de productos en el Atributo de la pantalla
  Future<void> _cargarProductos() async {
    setState(() {
      cargando = true;
      errorCarga = null;
    });
    try {
      //Llamo al Controlador para Obtener la lista de Productos
      final List<ProductoListado> productosRecibidos;
      if (widget.esCliente) {
        productosRecibidos = await widget.controladorCliente.listarProductos();
      } else {
        productosRecibidos = await controladorAdmin.cargarProductosPantalla();
      }

      if (!mounted) return;

      setState(() {
        productos = productosRecibidos;
        cargando = false;
        errorCarga = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorCarga = 'No se pudieron cargar los productos.';
        cargando = false;
      });
    }
  }

  // Construye la pantalla con los productos que coinciden con la búsqueda y la categoría.
  @override
  Widget build(BuildContext context) {
    final List<ProductoListado> visibles;
    if (widget.esCliente) {
      visibles = widget.controladorCliente.filtrarProductos(
        productos,
        busqueda,
        categoria,
      );
    } else {
      visibles = controladorAdmin.filtrarProductos(
        productos,
        busqueda,
        categoria,
      );
    }
    return Scaffold(
      body: SafeArea(
        child: _crearContenidoCentrado(context, visibles),
      ),
    );
  }

  Widget _crearEstructuraPantalla(BuildContext context, List<ProductoListado> visibles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _crearEncabezado(),
        _crearBotonVolver(context),
        if (widget.esCliente) ...[
          const SizedBox(height: 18),
          const PresentacionCliente(
            titulo: 'Explora los\nProductos',
            descripcion: 'Navegá nuestro catálogo de medicamentos, vitaminas y productos de cuidado personal con total confianza.',
          ),
        ] else
          _crearPresentacion(),
        const SizedBox(height: 22),
        _crearBuscador(),
        const SizedBox(height: 12),
        FiltrosProductos(
          productos: productos,
          categoria: categoria,
          alSeleccionar: (String seleccionada) {
            setState(() {
              categoria = seleccionada;
            });
          },
        ),
        const SizedBox(height: 12),
        if (cargando)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
        else if (errorCarga != null)
          Column(
            children: [
              Text(errorCarga!, textAlign: TextAlign.center),
              TextButton(
                onPressed: _cargarProductos,
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se encontraron productos.', textAlign: TextAlign.center),
          ),
        if (!cargando && errorCarga == null)
          for (final ProductoListado producto in visibles)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: widget.esCliente
                  ? _crearTarjetaCliente(producto)
                  : _crearTarjetaProducto(producto),
            ),
        if (widget.esCliente) ...[
          const SizedBox(height: 32),
          _crearBotonCarrito(context),
        ],
      ],
    );
  }

  Widget _crearBotonCarrito(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: agregando
            ? null
            : () async {
                await widget.controladorCliente.verCarrito(
                  context,
                );
                if (mounted) await _cargarProductos();
              },
        icon: const Icon(Icons.shopping_cart_outlined, size: 20),
        label: const Text('Ver carrito'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF008F8A),
          minimumSize: const Size(130, 36),
          textStyle: const TextStyle(fontSize: 12),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _crearBotonVolver(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          if (widget.esCliente) {
            widget.controladorCliente.volver(context);
          } else {
            controladorAdmin.volverAlMenu(context);
          }
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Volver'),
      ),
    );
  }

  // Construye el campo de búsqueda y actualiza el texto usado para filtrar los productos.
  Widget _crearBuscador() {
    if (widget.esCliente) {
      return BuscadorProductos(
        alCambiar: (String texto) {
          setState(() {
            busqueda = texto;
          });
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: (String texto) {
          // Solo actualizamos la presentación; el filtrado está en el controlador.
          setState(() {
            busqueda = texto;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: Icon(Icons.search, size: 30, color: Colors.black),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _crearTarjetaCliente(ProductoListado producto) {
    return TarjetaProductoCliente(
      producto: producto,
      acciones: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: agregando
                ? null
                : () async {
                    await widget.controladorCliente.verProducto(
                      context,
                      producto,
                    );
                    if (mounted) await _cargarProductos();
                  },
            icon: const Icon(Icons.visibility_outlined, size: 20),
            label: const Text('Ver'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontSize: 10),
              minimumSize: const Size(64, 28),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          TextButton.icon(
            onPressed: agregando || producto.stock < 1
                ? null
                : () async {
                    setState(() {
                      agregando = true;
                    });
                    await widget.controladorCliente.agregarProducto(
                      context,
                      producto,
                      1,
                    );
                    if (mounted) {
                      setState(() {
                        agregando = false;
                      });
                    }
                  },
            icon: const Icon(Icons.add_shopping_cart, size: 17),
            label: const Text('Agregar'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF168E88),
              backgroundColor: const Color(0xFFB9E8E5),
              textStyle: const TextStyle(fontSize: 10),
              minimumSize: const Size(64, 24),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // Organiza los datos y las acciones del producto según el espacio disponible.
  Widget _crearTarjetaProducto(ProductoListado producto) {
    if (widget.seleccionarParaHistorial || widget.seleccionarParaEdicion) {
      return Material(
        color: const Color(0xFFFFFDFD),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFBBBBBB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controladorAdmin.devolverProducto(context, producto),
          child: Padding(padding: const EdgeInsets.all(8), child: _crearDatosProducto(producto)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compacto =
              constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;
          final Widget detalle = _crearDatosProducto(producto);
          // Con poco ancho, las acciones bajan de fila para no cortar textos.
          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detalle,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [_crearBotonVer(producto), _crearBotonEditar(producto)],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: detalle),
              const SizedBox(width: 8),
              Column(children: [_crearBotonVer(producto), _crearBotonEditar(producto)]),
            ],
          );
        },
      ),
    );
  }

  // Construye el botón que solicita al controlador abrir el detalle del producto.
  Widget _crearBotonVer(ProductoListado producto) {
    return _crearBotonAccion(
      'Ver',
      'IconoOjo_ListarProductos.png',
      () async {
        await controladorAdmin.verProducto(context, producto);
        if (mounted) await _cargarProductos();
      },
    );
  }

  // Construye el botón que llama a la acción de editar del controlador.
  Widget _crearBotonEditar(ProductoListado producto) {
    return _crearBotonAccion(
      'Editar',
      'IconoLapis_ListarProductos.png',
      () async {
        final ProductoListado? editado = await controladorAdmin.editarProducto(context, producto);
        if (mounted && editado != null) await _cargarProductos();
      },
    );
  }

  // Construye un botón reutilizable con texto, un ícono y la acción que ejecutará al pulsarlo.
  Widget _crearBotonAccion(String titulo, String archivo, VoidCallback accion) {
    return TextButton.icon(
      onPressed: accion,
      icon: Image.asset(
        '$iconos/$archivo',
        width: 36,
        height: 36,
        excludeFromSemantics: true,
      ),
      label: Text(titulo, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado(BuildContext context, List<ProductoListado> visibles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _crearEstructuraPantalla(context, visibles),
        ),
      ),
    );
  }

  // Muestra el logo, el rol de administrador y el botón para cerrar sesión.
  Widget _crearEncabezado() {
    if (widget.esCliente) {
      return EncabezadoCliente(
        cerrarSesion: () {
          widget.controladorCliente.cerrarSesion(context);
        },
      );
    }
    return EncabezadoAdmin(cerrarSesion: () => controladorAdmin.cerrarSesion(context));
  }

  // Muestra el título del listado, su descripción y la ilustración del administrador.
  Widget _crearPresentacion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: turquesa, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.seleccionarParaHistorial ? 'Selección de Producto Historial' : 'Listado de productos',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Consulta y gestiona todos los productos registrados en el sistema.',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Image.asset(
                  '$iconos/IconoAdmin.png',
                  height: 145,
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

  // Obtiene la imagen del backend usando la ruta base y la FotoUrl del producto.
  Widget _crearImagenProducto(ProductoListado producto) {
    final String ruta = producto.fotoUrl?.trim() ?? '';
    final Widget imagenRespaldo = Image.asset(
      'assets/images/producto_default.png',
      width: 64,
      height: 80,
      fit: BoxFit.contain,
    );

    // Los registros sin foto o con rutas antiguas de assets usan la imagen predeterminada.
    if (ruta.isEmpty || ruta.startsWith('assets/')) {
      return imagenRespaldo;
    }

    return Image.network(
      ApiConfig.uri(ruta).toString(),
      width: 64,
      height: 80,
      fit: BoxFit.contain,
      semanticLabel: producto.nombre,
      errorBuilder: (context, error, stackTrace) {
        return imagenRespaldo;
      },
    );
  }

  // Muestra la imagen, el nombre, la descripción, el precio y el stock del producto.
  Widget _crearDatosProducto(ProductoListado producto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _crearImagenProducto(producto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(producto.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(producto.descripcion, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  Text('\$${producto.precio}',
                      style: const TextStyle(color: turquesa, fontWeight: FontWeight.bold)),
                  Text('Stock: ${producto.stock}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
