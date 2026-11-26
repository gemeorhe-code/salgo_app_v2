import 'dart:async';

import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/supabase_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/salgo_logo.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key});

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  bool _isSending = false;

  String get _email {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    return 'tu correo';
  }

  Future<void> _resend() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseAuthService.resendConfirmation(email: _email);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Si la cuenta existe, te enviamos un nuevo correo de confirmación.',
          ),
        ),
      );
    } on SupabaseAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo reenviar el correo.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SalgoLogo(size: 68),
                const SizedBox(height: AppDimensions.spaceXXL),
                Text(
                  'Revisa tu correo',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(fontSize: 28),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Enviamos un enlace de confirmación a $_email. '
                  'Ábrelo en este mismo dispositivo para completar el registro (PKCE).',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(height: 1.45),
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.orange),
                      SizedBox(width: AppDimensions.spaceM),
                      Expanded(
                        child: Text(
                          'Si el enlace venció o se abre desde otro dispositivo, '
                          'solicita uno nuevo desde aquí.',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                PrimaryButton(
                  label: _isSending
                      ? 'Reenviando correo...'
                      : 'Reenviar correo',
                  icon: Icons.send,
                  onPressed: _isSending ? null : _resend,
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
    );
  }
}
