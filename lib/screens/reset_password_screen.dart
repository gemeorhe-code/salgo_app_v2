import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_routes.dart';
import '../data/auth_notice.dart';
import '../data/auth_session_flow.dart';
import '../data/supabase_auth_service.dart';
import '../data/supabase_gate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/salgo_logo.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthNotice>().setRecoveryInProgress(true);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nueva contraseña';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    final SupabaseClient? client = SupabaseGate.client;
    if (client == null || client.auth.currentUser == null) {
      _backToLogin(
        'Abre el enlace de recuperación desde este mismo dispositivo.',
      );
      return;
    }

    setState(() => _isLoading = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseAuthService.updatePassword(
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.read<AuthNotice>().setRecoveryInProgress(false);
      context.read<AuthSessionFlow>().resetCurrentUser();
      await SupabaseAuthService.signOut();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña actualizada. Ingresa con tu nueva contraseña.',
          ),
        ),
      );
      _backToLogin();
    } on SupabaseAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la contraseña.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _backToLogin([String? message]) {
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SalgoLogo(size: 68),
                  const SizedBox(height: 24),
                  Text(
                    'Nueva contraseña',
                    textAlign: TextAlign.center,
                    style: AppTheme.display(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El enlace debe haberse abierto desde este mismo dispositivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Nueva contraseña',
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
                    label: _isLoading ? 'Guardando...' : 'Guardar contraseña',
                    icon: Icons.save,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Volver al inicio de sesión',
                    leading: const Icon(Icons.arrow_back),
                    onPressed: () => _backToLogin(),
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
