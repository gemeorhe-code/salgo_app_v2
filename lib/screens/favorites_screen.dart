import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/favorite_place_card.dart';
import '../widgets/salgo_header.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Place> favorites = PlacesScope.of(context).favorites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SalgoHeader(title: 'Favoritos', subtitle: 'Tus planes guardados'),
        Expanded(
          child: favorites.isEmpty
              ? const _EmptyFavorites()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final Place place = favorites[index];
                    return FavoritePlaceCard(
                      place: place,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.detail,
                        arguments: place.id,
                      ),
                      onRemove: () =>
                          PlacesScope.of(context).toggleFavorite(place.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 46,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: AppTheme.display(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el corazón de un lugar para guardarlo aquí y encontrarlo '
              'cuando quieras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
