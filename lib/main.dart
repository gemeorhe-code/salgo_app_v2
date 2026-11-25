import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_routes.dart';
import 'data/google_auth_service.dart';
import 'data/notifications_repository.dart';
import 'data/places_repository.dart';
import 'data/places_scope.dart';
import 'data/preferences_repository.dart';
import 'data/supabase_config.dart';
import 'data/supabase_gate.dart';
import 'data/user_profile_repository.dart';
import 'screens/detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/register_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      SupabaseGate.configure(Supabase.instance.client);
    } catch (_) {
      SupabaseGate.reset();
    }
  }

  final UserProfileRepository userProfile = UserProfileRepository();
  await userProfile.init();
  await GoogleAuthService.initialize();

  SharedPreferences? storage;
  try {
    storage = await SharedPreferences.getInstance();
  } catch (_) {}

  final PreferencesRepository preferences = PreferencesRepository();
  await preferences.init(storage);

  final NotificationsRepository notifications = NotificationsRepository(
    preferences: preferences,
  );
  await notifications.init(storage);

  runApp(
    SalgoApp(
      userProfile: userProfile,
      preferences: preferences,
      notifications: notifications,
    ),
  );
}

class SalgoApp extends StatefulWidget {
  const SalgoApp({
    super.key,
    this.userProfile,
    this.preferences,
    this.notifications,
  });

  final UserProfileRepository? userProfile;
  final PreferencesRepository? preferences;
  final NotificationsRepository? notifications;

  @override
  State<SalgoApp> createState() => _SalgoAppState();
}

class _SalgoAppState extends State<SalgoApp> {
  final PlacesRepository _repository = PlacesRepository();
  late final UserProfileRepository _userProfile =
      widget.userProfile ?? UserProfileRepository();
  late final PreferencesRepository _preferences;
  late final NotificationsRepository _notifications;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? PreferencesRepository();
    _notifications = widget.notifications ?? NotificationsRepository(
      preferences: _preferences,
    );
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget app = PlacesScope(
      repository: _repository,
        child: ChangeNotifierProvider<UserProfileRepository>.value(
        value: _userProfile,
        child: MaterialApp(
          title: 'SALGO APP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          initialRoute:
              _userProfile.isSignedIn ? AppRoutes.home : AppRoutes.login,
          routes: {
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.home: (_) => const HomeScreen(),
            AppRoutes.preferences: (_) => const PreferencesScreen(),
            AppRoutes.detail: (_) => const DetailScreen(),
            AppRoutes.editProfile: (_) => const EditProfileScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
            AppRoutes.placeDetail: (_) => const DetailScreen(),
          },
        ),
      ),
    );

    return ChangeNotifierProvider<PreferencesRepository>.value(
      value: _preferences,
      child: ChangeNotifierProvider<NotificationsRepository>.value(
        value: _notifications,
        child: app,
      ),
    );
  }
}
