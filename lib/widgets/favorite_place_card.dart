import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import 'place_image.dart';

class FavoritePlaceCard extends StatelessWidget {
  const FavoritePlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.onRemove,
  });

  final Place place;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 120, child: PlaceImage(place: place)),
            Expanded(
              child: Container(
                color: AppColors.orange,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceL,
                  AppDimensions.spaceM,
                  AppDimensions.spaceS,
                  AppDimensions.spaceM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title(
                              fontSize: 17,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            place.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              fontSize: 13,
                              color: AppColors.textLight.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceXS + 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.textLight,
                                size: 16,
                              ),
                              const SizedBox(width: AppDimensions.spaceXS),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: AppTypography.label(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar de favoritos',
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.favorite,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
