import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/supabase_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/salgo_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await SupabaseAuthService.requestPasswordReset(
        email: _emailController.text.trim(),
      );
    } on Object catch (_) {
      if (!mounted) return;
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Si el correo está registrado, te enviamos un enlace. '
          'Ábrelo desde este mismo dispositivo (PKCE).',
        ),
      ),
    );
    setState(() => _isLoading = false);
  }

  void _backToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXXL + 4,
              vertical: AppDimensions.spaceXXL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SalgoLogo(size: 68),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Text(
                    'Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: AppTypography.display(fontSize: 28),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    'Te enviaremos un enlace para crear una contraseña nueva',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 15,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.mail_outline,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  PrimaryButton(
                    label: _isLoading ? 'Enviando enlace...' : 'Enviar enlace',
                    icon: Icons.mail_outline,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  SecondaryButton(
                    label: 'Volver al inicio de sesión',
                    leading: const Icon(Icons.arrow_back),
                    onPressed: _backToLogin,
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
