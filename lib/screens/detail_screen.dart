import 'package:flutter/material.dart';

import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../widgets/place_image.dart';
import '../widgets/salgo_app_bar.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = PlacesScope.of(context);
    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    final Place? place = arguments is int
        ? repository.findById(arguments)
        : null;

    return Scaffold(
      appBar: SalgoAppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: place == null
          ? const Center(child: Text('No encontramos este lugar.'))
          : _DetailContent(
              place: place,
              onToggleFavorite: () {
                repository.toggleFavorite(place.id);
                _showSnack(
                  context,
                  place.isFavorite
                      ? 'Eliminado de favoritos'
                      : 'Agregado a favoritos',
                );
              },
            ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.place,
    required this.onToggleFavorite,
  });

  final Place place;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Gallery(place: place, onToggleFavorite: onToggleFavorite),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceXL,
              AppDimensions.spaceXL,
              AppDimensions.spaceXL,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: AppTypography.display(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    _FavoriteButton(
                      isFavorite: place.isFavorite,
                      onPressed: onToggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: AppTypography.label(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
                    Text(
                      '(${place.reviewCount} reseñas)',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    _CityChip(city: place.city),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceXL),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: place.address,
                ),
                _InfoRow(
                  icon: Icons.schedule,
                  label: 'Horario',
                  value: place.schedule,
                ),
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Precio',
                  value: place.price,
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Descripción',
                  style: AppTypography.display(fontSize: 22),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  place.description,
                  style: AppTypography.body(
                    fontSize: 15,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.place, required this.onToggleFavorite});

  final Place place;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned.fill(
            child: PlaceImage(place: place, iconSize: 84),
          ),
          Positioned(
            top: AppDimensions.spaceM,
            right: AppDimensions.spaceM,
            child: _FavoriteButton(
              isFavorite: place.isFavorite,
              onPressed: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
        onPressed: onPressed,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS - 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: AppColors.textLight, size: 14),
          const SizedBox(width: AppDimensions.spaceXS),
          Text(
            city,
            style: AppTypography.label(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: AppDimensions.spaceS + 2,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS + 6,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.mapButtonSize - 4,
            height: AppDimensions.mapButtonSize - 4,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(icon, color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS / 2),
                Text(
                  value,
                  style: AppTypography.label(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
