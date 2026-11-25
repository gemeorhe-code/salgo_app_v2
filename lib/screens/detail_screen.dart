import 'package:flutter/material.dart';

import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/place_image.dart';

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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          place?.name ?? 'Detalle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Gallery(place: place, onToggleFavorite: onToggleFavorite),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: AppTheme.display(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FavoriteButton(
                      isFavorite: place.isFavorite,
                      onPressed: onToggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${place.reviewCount} reseñas)',
                      style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _CityChip(city: place.city),
                  ],
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 8),
                Text('Descripción', style: AppTheme.display(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  place.description,
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.8),
                    height: 1.5,
                    fontSize: 15,
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
            top: 12,
            right: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place, color: AppColors.textLight, size: 14),
          const SizedBox(width: 4),
          Text(
            city,
            style: const TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
