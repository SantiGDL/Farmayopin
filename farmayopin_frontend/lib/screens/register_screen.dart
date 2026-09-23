import 'package:flutter/material.dart';

import '../controladores/controlador_general.dart';
import '../widgets/wave_background.dart';

// Esta vista dibuja widgets. Las acciones y validaciones están en el controlador.
// ================== ESTRUCTURA Y LÓGICA ==================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final controlador = ControladorGeneral();

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha notifyListeners del controlador y actualiza la presentación.
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Registro'), centerTitle: true),
          body: WaveBackground(
            showTopWave: false,
            child: SafeArea(
              child: _crearContenidoCentrado(),
            ),
          ),
        );
      },
    );
  }

  Widget _crearFormulario() {
    return Form(
      key: controlador.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      // Column ordena sus children verticalmente, como flex-direction: column.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _crearEncabezado(),
          const _FieldLabel(icon: Icons.person_outline, text: 'Nombre completo:'),
          _crearCampoNombre(),
          const SizedBox(height: 20),
          const _FieldLabel(icon: Icons.alternate_email, text: 'Correo electrónico:'),
          _crearCampoCorreo(),
          const SizedBox(height: 20),
          const _FieldLabel(icon: Icons.lock_outline, text: 'Contraseña:'),
          _crearCampoPassword(),
          const SizedBox(height: 20),
          const _FieldLabel(icon: Icons.lock_reset, text: 'Confirmar contraseña:'),
          _crearCampoConfirmacionPassword(),
          const SizedBox(height: 28),
          _crearBotonRegistro(),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => controlador.volver(context),
            child: const Text('Ya tengo cuenta'),
          ),
        ],
      ),
    );
  }

  Widget _crearCampoNombre() {
    return TextFormField(
      controller: controlador.nombreController,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(hintText: 'Ingrese su nombre'),
      validator: controlador.validarNombre,
    );
  }

  Widget _crearCampoCorreo() {
    return TextFormField(
      controller: controlador.correoController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(hintText: 'ejemplo@correo.com'),
      validator: controlador.validarCorreo,
    );
  }

  Widget _crearCampoPassword() {
    return TextFormField(
      controller: controlador.passwordController,
      obscureText: controlador.ocultarPassword,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Ingresá tu contraseña',
        suffixIcon: IconButton(
          onPressed: controlador.alternarPassword,
          icon: Icon(controlador.ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
      validator: controlador.validarPasswordRegistro,
    );
  }

  Widget _crearCampoConfirmacionPassword() {
    return TextFormField(
      controller: controlador.confirmacionController,
      obscureText: controlador.ocultarConfirmacion,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => controlador.registrarCliente(context),
      decoration: InputDecoration(
        hintText: 'Repetí la contraseña',
        suffixIcon: IconButton(
          onPressed: controlador.alternarConfirmacion,
          icon: Icon(
            controlador.ocultarConfirmacion
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: controlador.validarConfirmacion,
    );
  }

  Widget _crearBotonRegistro() {
    return FilledButton(
      // Un callback null deshabilita el botón mientras se envía la solicitud.
      onPressed: controlador.enviando
          ? null
          : () => controlador.registrarCliente(context),
      child: controlador.enviando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Registrarme'),
    );
  }

  // ================== DISEÑO Y PRESENTACIÓN ==================

  Widget _crearContenidoCentrado() {
    return SingleChildScrollView(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _crearFormulario(),
        ),
      ),
    );
  }

  Widget _crearEncabezado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Image.asset(
          'assets/images/farmayopin_logo.png',
          width: 220,
          semanticLabel: 'Farmayopin',
        ),
        const SizedBox(height: 18),
        const Text('Crear cuenta',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
      ],
    );
  }
}
// ================== COMPONENTES VISUALES ==================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
