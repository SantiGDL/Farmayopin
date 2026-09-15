import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/wave_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'Nombre': name,
        'Correo': email,
        'Pass': password,
        'Imagen': '',
      };

      final response = await _registerClient(body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Usuario registrado correctamente.');
        Navigator.of(context).pop();
      } else {
        final data = response.body.isNotEmpty
            ? _decodeResponse(response.body)
            : {'mensaje': 'No se pudo registrar el usuario.'};
        final message = data['mensaje'] ?? 'No se pudo registrar el usuario.';
        _showMessage(message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo conectar con el servidor. Revisá que el backend esté corriendo.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<http.Response> _registerClient(Map<String, String> payload) async {
    return http.post(
      Uri.parse('http://localhost:5206/api/controladorGeneral/nuevoCliente'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'mensaje': body};
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
     appBar: AppBar(
      title: const Text('Registro'),
      centerTitle: true,
      ),
      body: WaveBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Image.asset(
                      'assets/images/farmayopin_logo.png',
                      width: 220,
                      semanticLabel: 'Farmayopin',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _FieldLabel(icon: Icons.person_outline, text: 'Nombre completo:'),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'Ingrese su nombre'),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return 'Ingresá tu nombre completo.';
                          if (name.length < 2) return 'El nombre es demasiado corto.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel(icon: Icons.alternate_email, text: 'Correo electrónico:'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(hintText: 'ejemplo@correo.com'),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Ingresá tu correo electrónico.';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                            return 'Ingresá un correo válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel(icon: Icons.lock_outline, text: 'Contraseña:'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Ingresá tu contraseña',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) return 'Ingresá una contraseña.';
                          if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel(icon: Icons.lock_reset, text: 'Confirmar contraseña:'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _hideConfirmPassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitRegistration(),
                        decoration: InputDecoration(
                          hintText: 'Repetí la contraseña',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                            icon: Icon(
                              _hideConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final confirm = value ?? '';
                          if (confirm.isEmpty) return 'Confirmá tu contraseña.';
                          if (confirm != _passwordController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submitRegistration,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Registrarme'),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Ya tengo cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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


