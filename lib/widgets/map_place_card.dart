import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'place_image.dart';

class MapPlaceCard extends StatelessWidget {
  const MapPlaceCard({
    super.key,
    required this.place,
    required this.onFavorite,
    required this.onDetails,
  });

  final Place place;
  final VoidCallback onFavorite;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: SizedBox(
              width: 64,
              height: 64,
              child: PlaceImage(place: place, iconSize: 28),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title(fontSize: 15),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  place.category,
                  style: AppTypography.label(fontSize: 12, color: AppColors.teal),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  place.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: place.isFavorite
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
                icon: Icon(
                  place.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.orange,
                ),
                onPressed: onFavorite,
              ),
              FilledButton(
                onPressed: onDetails,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.textLight,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTypography.label(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                child: const Text('Ver detalle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
