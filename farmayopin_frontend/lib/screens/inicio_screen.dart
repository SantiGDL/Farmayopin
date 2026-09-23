import 'package:flutter/material.dart';

import '../servicios/sesion_cliente.dart';
import 'admin_home_screen.dart';
import 'cliente_home_screen.dart';
import 'login_screen.dart';

// ================== ESTRUCTURA Y LÓGICA ==================

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<void> recuperacion;
  @override
  void initState() {
    super.initState();
    recuperacion = SesionCliente.restaurar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: recuperacion,
      builder: (context, estado) {
        if (estado.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (estado.hasError) {
          return _crearErrorRecuperacion();
        }
        if (SesionCliente.rol == 'Admin') return const AdminHomeScreen();
        if (SesionCliente.rol == 'Cliente') return const ClienteHomeScreen();
        return const LoginScreen();
      },
    );
  }

  Widget _crearErrorRecuperacion() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se pudo recuperar la sesión.'),
            TextButton(
              onPressed: () => setState(() {
                recuperacion = SesionCliente.restaurar();
              }),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
