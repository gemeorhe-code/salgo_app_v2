import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';

class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.place, this.iconSize = 52});

  final Place place;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = place.imageUrl;
    final Widget placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.teal],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        MockData.iconForCategory(place.category),
        size: iconSize,
        color: Colors.white70,
      ),
    );

    if (imageUrl == null) return placeholder;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
