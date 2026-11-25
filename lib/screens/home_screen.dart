import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../data/mock_data.dart';
import '../data/notifications_repository.dart';
import '../data/places_scope.dart';
import '../models/place.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final List<Place> places = PlacesScope.of(context).places;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Category'),
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
          SizedBox(
            height: 240,
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
          ),
        ],
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
