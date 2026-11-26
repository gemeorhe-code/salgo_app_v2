import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/notifications_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';

class SalgoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SalgoAppBar({
    super.key,
    this.leading,
    this.extraActions = const <Widget>[],
  });

  final Widget? leading;
  final List<Widget> extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(
        'SALGO',
        style: AppTypography.display(
          fontSize: 26,
          color: AppColors.textLight,
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLight,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppDimensions.radiusL),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      actions: [
        ...extraActions,
        Consumer<NotificationsRepository>(
          builder: (context, notifications, _) {
            final int unreadCount = notifications.unreadCount;
            return IconButton(
              tooltip: 'Notificaciones',
              icon: Badge(
                backgroundColor: AppColors.orange,
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
            );
          },
        ),
        const SizedBox(width: AppDimensions.spaceS),
      ],
    );
  }
}
