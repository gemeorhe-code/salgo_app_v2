import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/salgo_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu correo';
    }
    final RegExp emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.+-]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    UserProfileRepository.of(context).registerLocal(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('¡Cuenta creada con éxito!')));
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SalgoLogo(size: 68),
                  const SizedBox(height: 24),
                  Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: AppTheme.display(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regístrate y empieza a planear tu salida',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Nombre completo',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline,
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.mail_outline,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirmar contraseña',
                    controller: _confirmController,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_reset,
                    obscureText: true,
                    validator: _validateConfirm,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Registrarse',
                    icon: Icons.person_add,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta?',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
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
    );
  }
}
