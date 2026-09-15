import 'package:flutter/material.dart';

import 'register_screen.dart';
import '../widgets/wave_background.dart';

/// StatefulWidget permite actualizar la visibilidad de la contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    // Liberamos los controladores cuando se cierra esta pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // TODO: llamar al servicio de autenticación con el correo y la contraseña.
    // Navegar al panel correspondiente solo cuando el servidor valide el acceso.
    _showMessage(
      'Formulario válido. El inicio de sesión aún no está disponible.',
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 64,
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: 'ejemplo@correo.com',
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Ingresá tu correo electrónico.';
                                  }
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(email)) {
                                    return 'Ingresá un correo válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              const _FieldLabel(
                                icon: Icons.lock_outline,
                                text: 'Contraseña:',
                              ),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  hintText: 'Ingresá tu contraseña',
                                  suffixIcon: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Ingresá tu contraseña.'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => _showMessage(
                                  'La recuperación de contraseña aún no está disponible.',
                                ),
                                child: const Text(
                                  '¿Olvidaste la contraseña?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _login,
                                child: const Text('Ingresar'),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    '¿No tenés cuenta?',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
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
