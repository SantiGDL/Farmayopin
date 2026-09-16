import 'package:flutter/material.dart';

import '../controladores/controlador_general.dart';
import '../widgets/wave_background.dart';

// Esta vista dibuja widgets. Las acciones y validaciones están en el controlador.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
          body: WaveBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // El scroll permite usar el formulario con el teclado abierto.
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 64,
                          ),
                          child: AutofillGroup(
                            child: Form(
                              key: controlador.formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      'assets/images/farmayopin_logo.png',
                                      width: 250,
                                      semanticLabel: 'Farmayopin',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tu farmacia, siempre contigo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  const Text(
                                    'Iniciar sesión',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  const _FieldLabel(
                                    icon: Icons.alternate_email,
                                    text: 'Correo electrónico:',
                                  ),
                                  TextFormField(
                                    controller: controlador.correoController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      hintText: 'ejemplo@correo.com',
                                    ),
                                    validator: controlador.validarCorreo,
                                  ),
                                  const SizedBox(height: 24),
                                  const _FieldLabel(
                                    icon: Icons.lock_outline,
                                    text: 'Contraseña:',
                                  ),
                                  TextFormField(
                                    controller: controlador.passwordController,
                                    obscureText: controlador.ocultarPassword,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        controlador.iniciarSesion(context),
                                    decoration: InputDecoration(
                                      hintText: 'Ingresá tu contraseña',
                                      suffixIcon: IconButton(
                                        tooltip: controlador.ocultarPassword
                                            ? 'Mostrar contraseña'
                                            : 'Ocultar contraseña',
                                        onPressed: controlador.alternarPassword,
                                        icon: Icon(
                                          controlador.ocultarPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: controlador.validarPasswordLogin,
                                  ),
                                  const SizedBox(height: 16),

                                  const SizedBox(height: 24),
                                  FilledButton(
                                    onPressed: () =>
                                        controlador.iniciarSesion(context),
                                    child: const Text('Ingresar'),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        '¿No tenés cuenta?',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            controlador.abrirRegistro(context),
                                        child: const Text(
                                          'Regístrate',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

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
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
