import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_routes.dart';
import '../data/location_service.dart';
import '../data/mock_data.dart';
import '../data/places_repository.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../utils/place_search.dart';
import '../widgets/city_chip.dart';
import '../widgets/map_place_card.dart';
import '../widgets/search_pill.dart';
import '../widgets/section_title.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.locationService});

  final LocationService? locationService;

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
  static const double _myLocationZoom = 16;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  late final LocationService _locationService;
  String _selectedCity = MockData.cities.first;
  int? _selectedPlaceId;
  GoogleMapController? _mapController;
  bool _myLocationEnabled = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounceTimer;
  String _typedSearchQuery = '';
  String _searchQuery = '';

  LatLng get _target => _cityCenters[_selectedCity] ?? _cityCenters.values.first;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSnackWithAction(
    String message,
    String actionLabel,
    VoidCallback onPressed,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(label: actionLabel, onPressed: onPressed),
        ),
      );
  }

  void _selectCity(String city) {
    final LatLng? center = _cityCenters[city];
    if (center == null) {
      return;
    }
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _typedSearchQuery = '';
      _searchQuery = '';
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

  void _onSearchChanged(String value) {
    _typedSearchQuery = value;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() => _searchQuery = _typedSearchQuery);
    });
    setState(() {});
  }

  void _onSearchEditingComplete() {
    _searchDebounceTimer?.cancel();
    if (mounted) setState(() => _searchQuery = _typedSearchQuery);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _typedSearchQuery = '';
      _searchQuery = '';
    });
  }

  List<Place> _searchResults(List<Place> allPlaces) {
    if (_searchQuery.trim().isEmpty) {
      return const <Place>[];
    }
    return searchPlaces(allPlaces, _searchQuery)
        .where((Place place) => _cityCenters.containsKey(place.city))
        .toList(growable: false);
  }

  void _selectSearchResult(Place place) {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _typedSearchQuery = '';
      _searchQuery = '';
      _selectedCity = place.city;
      _selectedPlaceId = place.id;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.lat, place.lng),
        _myLocationZoom,
      ),
    );
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

  Future<void> _goToMyLocation() async {
    try {
      final LocationOutcome outcome = await resolveCurrentLocation(
        _locationService,
      );

      if (!mounted) return;

      switch (outcome) {
        case LocationGpsDisabled():
          _showSnackWithAction(
            'El GPS está apagado. Actívalo para ver tu ubicación.',
            'Abrir ajustes',
            () => unawaited(_openLocationSettingsSafely()),
          );
        case LocationPermissionDenied():
          _showSnack('No pudimos acceder a tu ubicación sin permiso.');
        case LocationPermissionDeniedForever():
          _showSnackWithAction(
            'El permiso está desactivado. Actívalo en ajustes de la app.',
            'Abrir ajustes',
            () => unawaited(_openAppSettingsSafely()),
          );
        case LocationTimeout():
        case LocationFailure():
          _showSnack('No pudimos obtener tu ubicación. Inténtalo de nuevo.');
        case LocationSuccess(:final coordinates):
          setState(() => _myLocationEnabled = true);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(coordinates.latitude, coordinates.longitude),
              _myLocationZoom,
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('No pudimos obtener tu ubicación. Inténtalo de nuevo.');
    }
  }

  Future<void> _openLocationSettingsSafely() async {
    try {
      await _locationService.openLocationSettings();
    } catch (_) {
      if (!mounted) return;
      _showSnack('No pudimos abrir los ajustes de ubicación.');
    }
  }

  Future<void> _openAppSettingsSafely() async {
    try {
      await _locationService.openAppSettings();
    } catch (_) {
      if (!mounted) return;
      _showSnack('No pudimos abrir los ajustes de la app.');
    }
  }

  @override
  void initState() {
    super.initState();
    _locationService =
        widget.locationService ?? const GeolocatorLocationService();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlacesRepository repository = PlacesScope.of(context);
    final List<Place> allPlaces = repository.places;
    final List<Place> places = repository.placesByCity(_selectedCity);
    final List<Place> searchResults = _searchResults(allPlaces);
    final Place? selectedPlace = _selectedPlaceId == null
        ? null
        : _findPlace(places, _selectedPlaceId!);
    final double availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final double maxResultsHeight =
        (availableHeight * 0.22).clamp(88.0, 200.0).toDouble();
    final bool showSearchResults = _searchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'Mapa',
          subtitle: 'Explora lugares por ciudad',
        ),
        const SizedBox(height: AppDimensions.spaceS),
        _buildSearchBar(),
        const SizedBox(height: AppDimensions.spaceS),
        SizedBox(
          height: AppDimensions.cityChipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceL,
            ),
            itemCount: MockData.cities.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.spaceS),
            itemBuilder: (context, index) {
              final String city = MockData.cities[index];
              return CityChip(
                label: city,
                selected: city == _selectedCity,
                onTap: () => _selectCity(city),
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        if (showSearchResults)
          Flexible(
            fit: FlexFit.loose,
            child: _buildSearchResultsPanel(searchResults, maxResultsHeight),
          ),
        const SizedBox(height: AppDimensions.spaceM),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceL,
              0,
              AppDimensions.spaceL,
              AppDimensions.spaceL,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
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
                      myLocationEnabled: _myLocationEnabled,
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
                      right: AppDimensions.spaceM,
                      bottom: selectedPlace == null
                          ? AppDimensions.spaceM
                          : 168,
                      child: Column(
                        children: [
                          _MapActionButton(
                            icon: Icons.my_location,
                            tooltip: 'Mi ubicación',
                            onTap: _goToMyLocation,
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          _MapActionButton(
                            icon: Icons.add,
                            tooltip: 'Acercar',
                            onTap: _zoomIn,
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
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
                      left: AppDimensions.spaceM,
                      right: AppDimensions.spaceM,
                      bottom: AppDimensions.spaceM,
                      child: MapPlaceCard(
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
      ),
      child: SearchPill(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onEditingComplete: _onSearchEditingComplete,
        onClear: _clearSearch,
      ),
    );
  }

  Widget _buildSearchResultsPanel(List<Place> results, double maxHeight) {
    final double height = results.isEmpty ? 88.0 : maxHeight;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceL,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: AppShadows.card,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: results.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                  ),
                  child: Text(
                    'No encontramos lugares con ese texto',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _buildResultTile(results[index]),
              ),
      ),
    );
  }

  Widget _buildResultTile(Place place) {
    return ListTile(
      dense: true,
      leading: Icon(
        MockData.iconForCategory(place.category),
        color: AppColors.teal,
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.title(fontSize: 14),
      ),
      subtitle: Text(
        '${place.category} · ${place.city}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption(fontSize: 12),
      ),
      onTap: () => _selectSearchResult(place),
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
            width: AppDimensions.mapButtonSize,
            height: AppDimensions.mapButtonSize,
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
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
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceXXL + 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 40, color: AppColors.orange),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'No hay lugares en $city',
              textAlign: TextAlign.center,
              style: AppTypography.title(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
