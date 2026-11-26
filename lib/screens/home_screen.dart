import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/mock_data.dart';
import '../data/places_scope.dart';
import '../data/user_profile_repository.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../utils/place_search.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/place_card.dart';
import '../widgets/salgo_app_bar.dart';
import '../widgets/search_pill.dart';
import '../widgets/section_title.dart';
import 'favorites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SalgoAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeContent(),
          MapScreen(),
          FavoritesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _typedQuery = '';
  String _query = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _typedQuery = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (!mounted) return;
      setState(() => _query = _typedQuery);
    });
    setState(() {});
  }

  void _onSearchEditingComplete() {
    _debounceTimer?.cancel();
    if (mounted) setState(() => _query = _typedQuery);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() {
      _typedQuery = '';
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserProfileRepository profile = context.watch<UserProfileRepository>();
    final String rawName = profile.name.trim();
    final String displayName = rawName.isEmpty ? 'Usuario' : rawName;
    final String firstName = displayName.split(RegExp(r'\s+')).first;
    final String city = profile.city.trim().isEmpty
        ? 'Bucaramanga'
        : profile.city.trim();
    final String dateLabel = _todayLabel();
    final List<Place> places = searchPlaces(
      PlacesScope.of(context).places,
      _query,
    );
    final bool isSearching = _query.trim().isNotEmpty;
    final double availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final double recommendedHeight =
        (availableHeight * 0.38).clamp(120.0, 240.0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Greeting(name: firstName, city: city, dateLabel: dateLabel),
          _buildSearchBar(),
          if (!isSearching) const SectionTitle(title: 'Categorías'),
          if (!isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
              ),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.spaceS,
                crossAxisSpacing: AppDimensions.spaceS,
                childAspectRatio: 0.82,
                children: [
                  for (final category in MockData.categories)
                    CategoryCard(
                      category: category,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.preferences,
                        arguments: category.name,
                      ),
                    ),
                ],
              ),
            ),
          const SectionTitle(
            title: 'Recomendados para ti',
            trailing: _ViewAllLabel(),
          ),
          _buildRecommended(places, recommendedHeight),
        ],
      ),
    );
  }

  String _todayLabel() {
    const List<String> weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final DateTime now = DateTime.now();
    final String moment = now.hour < 12
        ? 'mañana'
        : now.hour < 19
        ? 'tarde'
        : 'noche';
    final String label = '${weekdays[now.weekday - 1]} por la $moment';
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceL,
        AppDimensions.spaceM,
        AppDimensions.spaceL,
        AppDimensions.spaceXS,
      ),
      child: SearchPill(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onEditingComplete: _onSearchEditingComplete,
        onClear: _clearSearch,
      ),
    );
  }

  Widget _buildRecommended(List<Place> places, double height) {
    if (places.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXXL,
            ),
            child: Text(
              'No encontramos lugares con ese texto',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
        ),
        itemCount: places.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.spaceM),
        itemBuilder: (context, index) {
          final Place place = places[index];
          return PlaceCard(
            place: place,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.detail,
              arguments: place.id,
            ),
          );
        },
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.city,
    required this.dateLabel,
  });

  final String name;
  final String city;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spaceL,
        AppDimensions.spaceL,
        AppDimensions.spaceL,
        AppDimensions.spaceXS,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hola, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    fontSize: 22,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  '¿Qué plan hoy?',
                  style: AppTypography.title(
                    fontSize: 18,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    Flexible(
                      child: Text(
                        '$city · $dateLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          fontSize: 12,
                          color: AppColors.textLight.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.explore_outlined,
            size: 44,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }
}

class _ViewAllLabel extends StatelessWidget {
  const _ViewAllLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Ver todo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(fontSize: 12, color: AppColors.orange),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceXS),
        const Icon(
          Icons.chevron_right,
          size: 14,
          color: AppColors.orange,
        ),
      ],
    );
  }
}
