import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/user_profile_repository.dart';
import '../data/places_repository.dart';
import '../data/places_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/salgo_header.dart';
import '../widgets/secondary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _editProfile(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  void _showNotifications(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final UserProfileRepository upRepository =
        UserProfileRepository.of(context);
    final PlacesRepository repository = PlacesScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SalgoHeader(title: 'PERFIL', subtitle: 'Tu cuenta SALGO'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: upRepository,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.orange, AppColors.teal],
                              ),
                              border: Border.all(color: AppColors.teal, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textDark.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          child: upRepository.photoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(56),
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
                          const SizedBox(height: 16),
                          Text(
                            upRepository.name,
                            textAlign: TextAlign.center,
                            style: AppTheme.display(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            upRepository.email,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textDark.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: repository,
                  builder: (context, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Favoritos',
                            value: '${repository.favorites.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Ciudad',
                            value: upRepository.city,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _OptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Editar perfil',
                  onTap: () => _editProfile(context),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.tune,
                  label: 'Mis preferencias',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.preferences),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.notifications_none,
                  label: 'Notificaciones',
                  onTap: () => _showNotifications(context),
                ),
                const SizedBox(height: 24),
                SecondaryButton(
                  label: 'Cerrar sesión',
                  leading: const Icon(Icons.logout),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await repository.onSignedOut();
                    final String? error = await upRepository.signOut();
                    if (!context.mounted) return;
                    if (error != null) {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.teal.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}