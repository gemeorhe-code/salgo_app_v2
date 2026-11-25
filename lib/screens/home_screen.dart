import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/mock_data.dart';
import '../data/notifications_repository.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/place_search.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/category_card.dart';
import '../widgets/place_card.dart';
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
      appBar: AppBar(
        title: Text(
          'SALGO',
          style: AppTheme.display(fontSize: 26, color: AppColors.textLight),
        ),
        actions: [
          Consumer<NotificationsRepository>(
            builder: (context, notifications, _) {
              final int unreadCount = notifications.unreadCount;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_none),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          if (!isSearching) const _SectionTitle('Category'),
          if (!isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
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
          const _SectionTitle('Recommended'),
          _buildRecommended(places, recommendedHeight),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onEditingComplete: _onSearchEditingComplete,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar lugares',
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _clearSearch,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildRecommended(List<Place> places, double height) {
    if (places.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No encontramos lugares con ese texto',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Text(title, style: AppTheme.display(fontSize: 24)),
    );
  }
}
