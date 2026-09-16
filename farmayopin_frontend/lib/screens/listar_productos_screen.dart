import 'package:flutter/material.dart';

import '../controladores/controlador_admin.dart';
import '../dtos/producto_listado.dart';
import '../config/api_config.dart';

//ListarProductosScreen define el widget y recibe su configuración.
class ListarProductosScreen extends StatefulWidget {
  const ListarProductosScreen({super.key}); //Constructor

  @override
  State<ListarProductosScreen> createState() {
    return _ListarProductosScreenState();
  }
}
//_ListarProductosScreenState guarda los datos cambiantes y su build() construye toda la interfaz, incluyendo títulos, botones y productos.
class _ListarProductosScreenState extends State<ListarProductosScreen> {
  //Variables
  final ControladorAdmin controladorAdmin = const ControladorAdmin();
  List<ProductoListado> productos = [];
  bool cargando = true;
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
  Future<void> _cargarProductos() async 
  {
    try 
    {
      //Llamo al Controlador para Obtener la lista de Productos
      final List<ProductoListado> productosRecibidos = await controladorAdmin.cargarProductosPantalla();

      if (!mounted) return;

      setState(() {productos = productosRecibidos; cargando = false; errorCarga = null;});
    } catch (error) 
    {
      if (!mounted) return;

      setState(() {errorCarga = 'No se pudieron cargar los productos.';cargando = false;});
    }
  }


  // Construye la pantalla con los productos que coinciden con la búsqueda y la categoría.
  @override
  Widget build(BuildContext context)
  {
    final List<ProductoListado> visibles = controladorAdmin.filtrarProductos(productos, busqueda, categoria);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _encabezado(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => controladorAdmin.volverAlMenu(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ),
                  _presentacion(),
                  const SizedBox(height: 22),
                  _buscador(),
                  // Pendiente: habilitar cuando el backend devuelva la categoría.
                  // const SizedBox(height: 20),
                  // _filtros(),
                  const SizedBox(height: 12),
                  if (visibles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No se encontraron productos.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final ProductoListado producto in visibles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _filaProducto(producto),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Muestra el logo, el rol de administrador y el botón para cerrar sesión.
  Widget _encabezado()
  {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/farmayopin_logo.png',
              width: 100,
              semanticLabel: 'Farmayopin',
            ),
            const Text(
              'Administrador',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => controladorAdmin.cerrarSesion(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFEEEEEE),
          ),
        ),
      ],
    );
  }

  // Muestra el título del listado, su descripción y la ilustración del administrador.
  Widget _presentacion()
  {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: turquesa,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listado de productos',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Consulta y gestiona todos los productos registrados en el sistema.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
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

  // Construye el campo de búsqueda y actualiza el texto usado para filtrar los productos.
  Widget _buscador()
  {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: (String texto)
        {
          // Solo actualizamos la presentación; el filtrado está en el controlador.
          setState(() {busqueda = texto;});
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

  // Pendiente: habilitar cuando el backend devuelva la categoría.
  /*
  // Construye los botones de categorías y guarda la categoría seleccionada.
  Widget _filtros()
  {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        for (final String opcion in ['Todos', 'Medicamentos', 'Vitaminas'])
          ChoiceChip(
            label: Text(opcion, style: const TextStyle(fontSize: 12)),
            selected: categoria == opcion,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFD3FDF0),
            side: const BorderSide(color: turquesa),
            shape: const StadiumBorder(),
            onSelected: (bool seleccionado)
            {
              setState(() {categoria = opcion;});
            },
          ),
      ],
    );
  }

  */

  // Organiza los datos y las acciones del producto según el espacio disponible.
  Widget _filaProducto(ProductoListado producto)
  {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFD),
        border: Border.all(color: const Color(0xFFBBBBBB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints)
        {
          final bool compacto = constraints.maxWidth < 330 || MediaQuery.textScalerOf(context).scale(14) > 18;
          final Widget detalle = _detalleProducto(producto);
          // Con poco ancho, las acciones bajan de fila para no cortar textos.
          if (compacto)
          {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detalle,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [_ver(producto), _editar(producto)],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: detalle),
              const SizedBox(width: 8),
              Column(children: [_ver(producto), _editar(producto)]),
            ],
          );
        },
      ),
    );
  }

  // Obtiene la imagen del backend usando la ruta base y la FotoUrl del producto.
  Widget _imagenProducto(ProductoListado producto)
  {
    final String ruta = producto.fotoUrl?.trim() ?? '';
    final Widget imagenRespaldo = Image.asset(
      'assets/images/producto_default.png',
      width: 64,
      height: 80,
      fit: BoxFit.contain,
    );

    // Los registros sin foto o con rutas antiguas de assets usan la imagen predeterminada.
    if (ruta.isEmpty || ruta.startsWith('assets/'))
    {
      return imagenRespaldo;
    }

    return Image.network(
      ApiConfig.uri(ruta).toString(),
      width: 64,
      height: 80,
      fit: BoxFit.contain,
      semanticLabel: producto.nombre,
      errorBuilder: (context, error, stackTrace)
      {
        return imagenRespaldo;
      },
    );
  }

  // Muestra la imagen, el nombre, la descripción, el precio y el stock del producto.
  Widget _detalleProducto(ProductoListado producto)
  {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imagenProducto(producto),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(producto.descripcion, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 4,
                children: [
                  Text(
                    '\$${producto.precio}',
                    style: const TextStyle(
                      color: turquesa,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stock: ${producto.stock}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construye el botón que solicita al controlador abrir el detalle del producto.
  Widget _ver(ProductoListado producto)
  {
    return _accion(
      'Ver',
      'IconoOjo_ListarProductos.png',
      () => controladorAdmin.verProducto(context, producto),
    );
  }

  // Construye el botón que llama a la acción de editar del controlador.
  Widget _editar(ProductoListado producto)
  {
    return _accion(
      'Editar',
      'IconoLapis_ListarProductos.png',
      () => controladorAdmin.editarProducto(context, producto),
    );
  }

  // Construye un botón reutilizable con texto, un ícono y la acción que ejecutará al pulsarlo.
  Widget _accion(String titulo, String archivo, VoidCallback accion)
  {
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
}
