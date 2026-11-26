import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
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
        SalgoHeader(
          title: 'Favoritos',
          subtitle: 'Tus planes guardados',
          background: AppColors.teal,
        ),
        Expanded(
          child: favorites.isEmpty
              ? const _EmptyFavorites()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceL,
                    AppDimensions.spaceL,
                    AppDimensions.spaceL,
                    AppDimensions.spaceXXL,
                  ),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spaceM + 2),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceXXL + 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 46,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            Text(
              'Aún no tienes favoritos',
              textAlign: TextAlign.center,
              style: AppTypography.display(fontSize: 22),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Toca el corazón de un lugar para guardarlo aquí y encontrarlo '
              'cuando quieras.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
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
