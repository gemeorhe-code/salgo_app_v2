import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/auth_session_flow.dart';
import '../data/place_admin_repository.dart';
import '../data/user_profile_repository.dart';
import '../data/notifications_repository.dart';
import '../data/places_repository.dart';
import '../data/places_scope.dart';
import '../data/preferences_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../widgets/option_row.dart';
import '../widgets/secondary_button.dart';
import '../widgets/stat_card.dart';
import 'admin_places_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Duration _signOutTimeout = Duration(seconds: 10);

  bool _isSigningOut = false;
  bool _canManagePlaces = false;
  late final PlaceAdminRepository _placeAdminRepository;

  @override
  void initState() {
    super.initState();
    _placeAdminRepository = PlaceAdminRepository();
    unawaited(_loadPlaceAccess());
  }

  Future<void> _loadPlaceAccess() async {
    final bool canManage =
        (await _placeAdminRepository.fetchAccess()).canManage;
    if (!mounted || !canManage) return;
    setState(() => _canManagePlaces = true);
  }

  void _editProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  void _showNotifications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  Future<void> _signOut(BuildContext context, PlacesRepository repository) async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    try {
      final PreferencesRepository prefsRepo = context
          .read<PreferencesRepository>();
      final NotificationsRepository notificationsRepo = context
          .read<NotificationsRepository>();
      final AuthSessionFlow authFlow = context.read<AuthSessionFlow>();
      final UserProfileRepository upRepository = UserProfileRepository.of(
        context,
      );
      await prefsRepo.onSignedOut().timeout(_signOutTimeout);
      await notificationsRepo.onSignedOut().timeout(_signOutTimeout);
      await repository.onSignedOut().timeout(_signOutTimeout);
      authFlow.resetCurrentUser();
      error = await upRepository.signOut().timeout(_signOutTimeout);
    } on Object {
      error =
          'No se pudo cerrar la sesión correctamente. Se cerrará la app localmente.';
    } finally {
      if (context.mounted) {
        setState(() => _isSigningOut = false);
        if (error != null) {
          messenger.showSnackBar(SnackBar(content: Text(error)));
        }
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserProfileRepository upRepository = UserProfileRepository.of(
      context,
    );
    final PlacesRepository repository = PlacesScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXL + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceL,
              AppDimensions.spaceL,
              AppDimensions.spaceL,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: upRepository,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceXL,
                        vertical: AppDimensions.spaceXXL,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.primary,
                              border: Border.all(
                                color: AppColors.teal,
                                width: 3,
                              ),
                              boxShadow: AppShadows.floating,
                            ),
                            child: upRepository.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusL * 2 + 8,
                                    ),
                                    child: Image.network(
                                      upRepository.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppColors.textLight,
                                  ),
                          ),
                          const SizedBox(height: AppDimensions.spaceL),
                          Text(
                            upRepository.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.display(fontSize: 24),
                          ),
                          if (upRepository.email.trim().isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.spaceXS),
                            Text(
                              upRepository.email,
                              textAlign: TextAlign.center,
                              style: AppTypography.body(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spaceL),
                ListenableBuilder(
                  listenable: repository,
                  builder: (context, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Favoritos',
                            value: '${repository.favorites.length}',
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: StatCard(
                            label: 'Ciudad',
                            value: upRepository.city,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                OptionRow(
                  icon: Icons.edit_outlined,
                  label: 'Editar perfil',
                  onTap: () => _editProfile(context),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                OptionRow(
                  icon: Icons.tune,
                  label: 'Mis preferencias',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.preferences),
                ),
                if (_canManagePlaces) ...[
                  const SizedBox(height: AppDimensions.spaceS),
                  OptionRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administrar lugares',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminPlacesScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppDimensions.spaceS),
                OptionRow(
                  icon: Icons.notifications_none,
                  label: 'Notificaciones',
                  onTap: () => _showNotifications(context),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                SecondaryButton(
                  label: _isSigningOut ? 'Cerrando sesión…' : 'Cerrar sesión',
                  leading: const Icon(Icons.logout),
                  onPressed: _isSigningOut
                      ? null
                      : () => unawaited(_signOut(context, repository)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
