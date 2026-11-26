import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: AppShadows.navigation,
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.textLight,
          unselectedItemColor: AppColors.textLight.withValues(alpha: 0.72),
          selectedLabelStyle: AppTypography.label(
            fontSize: 11,
            color: AppColors.textLight,
          ),
          unselectedLabelStyle: AppTypography.caption(
            fontSize: 11,
            color: AppColors.textLight.withValues(alpha: 0.72),
          ),
          currentIndex: selectedIndex,
          onTap: onChanged,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
