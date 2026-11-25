import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_routes.dart';
import '../data/mock_data.dart';
import '../data/places_repository.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../widgets/place_image.dart';
import '../widgets/salgo_header.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Map<String, LatLng> _cityCenters = {
    'Bucaramanga': LatLng(7.1196, -73.1148),
    'Floridablanca': LatLng(7.0620, -73.0920),
    'Piedecuesta': LatLng(6.9873, -73.0498),
  };

  static const double _cityZoom = 13;

  String _selectedCity = MockData.cities.first;
  int? _selectedPlaceId;
  GoogleMapController? _mapController;

  LatLng get _target => _cityCenters[_selectedCity] ?? _cityCenters.values.first;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectCity(String city) {
    final LatLng? center = _cityCenters[city];
    if (center == null) {
      return;
    }
    setState(() {
      _selectedCity = city;
      _selectedPlaceId = null;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(center, _cityZoom),
    );
  }

  void _selectPlace(int id) {
    setState(() => _selectedPlaceId = id);
  }

  void _clearSelection() {
    if (_selectedPlaceId == null) return;
    setState(() => _selectedPlaceId = null);
  }

  Set<Marker> _buildMarkers(List<Place> places) {
    return <Marker>{
      for (final Place place in places)
        Marker(
          markerId: MarkerId('${place.id}'),
          position: LatLng(place.lat, place.lng),
          infoWindow: InfoWindow(title: place.name, snippet: place.category),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.id == _selectedPlaceId
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueOrange,
          ),
          zIndexInt: place.id == _selectedPlaceId ? 1 : 0,
          onTap: () => _selectPlace(place.id),
        ),
    };
  }

  Place? _findPlace(List<Place> places, int id) {
    for (final Place place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlacesRepository repository = PlacesScope.of(context);
    final List<Place> places = repository.placesByCity(_selectedCity);
    final Place? selectedPlace = _selectedPlaceId == null
        ? null
        : _findPlace(places, _selectedPlaceId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalgoHeader(
          title: 'Mapa',
          subtitle: 'Explora lugares por ciudad',
          trailing: IconButton(
            tooltip: 'Filtros',
            onPressed: () => _showSnack('Filtros próximamente'),
            icon: const Icon(Icons.tune, color: AppColors.textLight),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: MockData.cities.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final String city = MockData.cities[index];
              return _CityChip(
                label: city,
                selected: city == _selectedCity,
                onTap: () => _selectCity(city),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _target,
                        zoom: _cityZoom,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (_) => _clearSelection(),
                      markers: _buildMarkers(places),
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                    ),
                  ),
                  if (places.isEmpty)
                    Positioned.fill(
                      child: _EmptyCityNotice(city: _selectedCity),
                    )
                  else
                    Positioned(
                      right: 12,
                      bottom: selectedPlace == null ? 12 : 168,
                      child: Column(
                        children: [
                          _MapActionButton(
                            icon: Icons.add,
                            tooltip: 'Acercar',
                            onTap: _zoomIn,
                          ),
                          const SizedBox(height: 8),
                          _MapActionButton(
                            icon: Icons.remove,
                            tooltip: 'Alejar',
                            onTap: _zoomOut,
                          ),
                        ],
                      ),
                    ),
                  if (selectedPlace != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _PlaceCard(
                        place: selectedPlace,
                        onFavorite: () =>
                            repository.toggleFavorite(selectedPlace.id),
                        onDetails: () => Navigator.pushNamed(
                          context,
                          AppRoutes.detail,
                          arguments: selectedPlace.id,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.teal : AppColors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected
                  ? AppColors.teal
                  : AppColors.teal.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textLight : AppColors.teal,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onFavorite,
    required this.onDetails,
  });

  final Place place;
  final VoidCallback onFavorite;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: PlaceImage(place: place, iconSize: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.category,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ver detalle',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCityNotice extends StatelessWidget {
  const _EmptyCityNotice({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 40, color: AppColors.orange),
            const SizedBox(height: 10),
            Text(
              'No hay lugares en $city',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
