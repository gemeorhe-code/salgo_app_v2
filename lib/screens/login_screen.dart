import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_routes.dart';
import '../data/google_auth_service.dart';
import '../data/supabase_auth_service.dart';
import '../data/user_profile_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_icon.dart';
import '../widgets/primary_button.dart';
import '../widgets/salgo_logo.dart';
import '../widgets/secondary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // El login con correo sigue siendo local; Supabase Auth se hará en la Fase A2.
    UserProfileRepository.of(
      context,
    ).signInWithEmail(email: _emailController.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('¡Bienvenido a SALGO!')));
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      final GoogleAuthUser user = await GoogleAuthService.signIn();
      final AuthResponse response = await SupabaseAuthService.signInWithGoogle(
        user,
      );
      final User? supabaseUser = response.user;
      if (!mounted) return;

      if (supabaseUser == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Supabase no devolvió una sesión válida. Inténtalo de nuevo.',
            ),
          ),
        );
        return;
      }

      final String? syncError = await UserProfileRepository.of(
        context,
      ).completeGoogleSignIn(googleUser: user, supabaseUser: supabaseUser);
      if (!mounted) return;

      if (syncError != null) {
        messenger.showSnackBar(SnackBar(content: Text(syncError)));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('¡Bienvenido, ${user.name}!')),
        );
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on GoogleAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on SupabaseAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar sesión con Google.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  const SalgoLogo(),
                  const SizedBox(height: 32),
                  Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: AppTheme.display(fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa para descubrir planes en Bucaramanga',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Ingresar',
                    icon: Icons.login,
                    onPressed: _isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: _isLoading
                        ? 'Conectando con Google...'
                        : 'Iniciar sesión con Google',
                    leading: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const GoogleIcon(),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'Registrarse aquí',
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
