import 'package:flutter/material.dart';

import 'crear_producto_screen.dart';
import 'login_screen.dart';

// Esta pantalla no tiene datos que cambien: por eso usa StatelessWidget.
// Para leerla, empezá por build y seguí los métodos de cada sección.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // Equivalen a variables de CSS: los estilos compartidos se definen una vez.
  static const _bannerColor = Color(0xFF50BDB5);
  static const _iconBackground = Color(0xFF8BE1BD);
  static const _secondaryText = Color(0xFF929299);
  static const _iconsPath =
      'assets/Admin_PantallaPrincipal/IconosPantallaPrincipalAdmin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Center(
            // Como max-width en CSS: evita estirar las tarjetas en escritorio.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildWelcomeCard(),
                  const SizedBox(height: 28),
                  _buildProductMenu(context),
                  const SizedBox(height: 28),
                  _buildPurchaseHistoryCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // Wrap permite que el botón pase abajo si no queda espacio horizontal.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, size: 26),
            label: const Text('Cerrar sesión'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color(0xFFEEEEEE),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bannerColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PANEL ADMINISTRADOR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de artículos de farmacia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Accedé rápidamente a las funciones administrativas del sistema',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Como <img src="..."> en HTML: carga una imagen de assets.
              Image.asset(
                '$_iconsPath/IconoAdmin.png',
                width: 120,
                height: 140,
                fit: BoxFit.contain,
                semanticLabel: 'Frasco de farmacia',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductMenu(BuildContext context) {
    // LayoutBuilder obtiene el ancho real disponible, como un contenedor CSS.
    // Wrap arma dos columnas, o una en pantallas muy angostas.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 340
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 36,
          children: [
            _buildProductCard(
              width: cardWidth,
              title: 'Listar productos',
              description: 'Ver todos los productos registrados en el sistema.',
              iconFile: 'IconoListarProductos.png',
              onTap: () => _showPendingFeature(context, 'Listar productos'),
            ),
            _buildProductCard(
              width: cardWidth,
              title: 'Crear producto',
              description: 'Agregar nuevos productos al inventario.',
              iconFile: 'IconoCrearProducto.png',
              onTap: () => _openCreateProduct(context),
            ),
            _buildProductCard(
              width: cardWidth,
              title: 'Ver producto',
              description: 'Ver información detallada del producto.',
              iconFile: 'IconoVerProducto.png',
              onTap: () => _showPendingFeature(context, 'Ver producto'),
            ),
            _buildProductCard(
              width: cardWidth,
              title: 'Editar producto',
              description: 'Modificar la información de productos existentes.',
              iconFile: 'IconoEditarProducto.png',
              onTap: () => _showPendingFeature(context, 'Editar producto'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard({
    required double width,
    required String title,
    required String description,
    required String iconFile,
    required VoidCallback onTap,
  }) {
    // Los parámetros con nombre se parecen a los argumentos nombrados de C#.
    // VoidCallback es una función sin parámetros ni retorno (como Action).
    return SizedBox(
      width: width,
      child: _buildMenuCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('$_iconsPath/$iconFile', width: 66, height: 66),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: _secondaryText, fontSize: 12),
            ),
            Align(alignment: Alignment.centerRight, child: _buildArrow()),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryCard(BuildContext context) {
    return _buildMenuCard(
      onTap: () => _showPendingFeature(context, 'Histórico de compras'),
      child: Row(
        children: [
          Image.asset(
            '$_iconsPath/IconoHistoricoDeCompra1Prod.png',
            width: 66,
            height: 66,
          ), 
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de Compras',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Ver historial de compras realizadas\n(Fecha, Cantidad, Cliente).',
                  style: TextStyle(fontSize: 12, color: _secondaryText),
                ),
              ],
            ),
          ),
          _buildArrow(),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required Widget child, required VoidCallback onTap}) {
    // Material define el borde y la sombra. InkWell hace clickeable la tarjeta
    // completa y muestra una respuesta visual al tocarla.
    final borderRadius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: const EdgeInsets.all(10), child: child),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: Color(0xFFD9D9D9),
      child: Icon(Icons.chevron_right, color: Colors.black, size: 30),
    );
  }

  void _openCreateProduct(BuildContext context) {
    // push abre otra pantalla; pop permite volver al panel.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CrearProductoScreen()));
  }

  void _showPendingFeature(BuildContext context, String feature) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('$feature todavía no está disponible.')),
    );
  }

  void _logout(BuildContext context) {
    // Por ahora solo vuelve al login y limpia la navegación.
    // Al integrar autenticación, también habrá que borrar la sesión guardada.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
