import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_routes.dart';
import 'data/auth_notice.dart';
import 'data/auth_session_flow.dart';
import 'data/google_auth_service.dart';
import 'data/local_auth_migration.dart';
import 'data/notifications_repository.dart';
import 'data/places_repository.dart';
import 'data/places_scope.dart';
import 'data/preferences_repository.dart';
import 'data/supabase_config.dart';
import 'data/supabase_gate.dart';
import 'data/user_profile_repository.dart';
import 'screens/check_email_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/register_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/reset_password_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/favorites_sync_bridge.dart';

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

  SharedPreferences? storage;
  try {
    storage = await SharedPreferences.getInstance();
  } on Object {
    storage = null;
  }

  final UserProfileRepository userProfile = UserProfileRepository();
  await userProfile.init();
  await GoogleAuthService.initialize();

  final LocalAuthMigration migration = LocalAuthMigration(storage: storage);
  final bool hasSupabaseSession = SupabaseGate.client?.auth.currentUser != null;
  if (!hasSupabaseSession) {
    await migration.ensurePendingFromLocalData();
    userProfile.clearLocalSessionFlag();
  }

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
      migration: migration,
    ),
  );
}

class SalgoApp extends StatefulWidget {
  const SalgoApp({
    super.key,
    this.userProfile,
    this.preferences,
    this.notifications,
    this.migration,
  });

  final UserProfileRepository? userProfile;
  final PreferencesRepository? preferences;
  final NotificationsRepository? notifications;
  final LocalAuthMigration? migration;

  @override
  State<SalgoApp> createState() => _SalgoAppState();
}

class _SalgoAppState extends State<SalgoApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final PlacesRepository _repository = PlacesRepository();
  final AuthNotice _authNotice = AuthNotice();
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastSignedInUserId;

  late final UserProfileRepository _userProfile =
      widget.userProfile ?? UserProfileRepository();
  late final PreferencesRepository _preferences;
  late final NotificationsRepository _notifications;
  late final LocalAuthMigration _migration;
  late final AuthSessionFlow _authFlow;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences ?? PreferencesRepository();
    _notifications =
        widget.notifications ??
        NotificationsRepository(preferences: _preferences);
    _migration = widget.migration ?? LocalAuthMigration();
    _authFlow = AuthSessionFlow(
      userProfile: _userProfile,
      preferences: _preferences,
      notifications: _notifications,
      places: _repository,
      migration: _migration,
    );
    _authNotice.addListener(_handleAuthNotice);
    unawaited(_repository.init());
    unawaited(_loadRemoteState());
    _subscribeToAuth();
  }

  Future<void> _loadRemoteState() async {
    final User? user = SupabaseGate.client?.auth.currentUser;
    if (user == null) return;
    _lastSignedInUserId = user.id;
    await _authFlow.completeEmailSignIn(user: user);
  }

  void _subscribeToAuth() {
    final SupabaseClient? client = SupabaseGate.client;
    if (client == null) return;
    _authSubscription = client.auth.onAuthStateChange.listen(
      (AuthState state) => unawaited(_handleAuthState(state)),
      onError: (Object error, StackTrace stackTrace) {
        unawaited(
          _migration.pendingEmail().then((String? email) {
            _showNotice(
              'El enlace venció o no es válido. Solicita uno nuevo.',
              route: email != null ? AppRoutes.checkEmail : AppRoutes.login,
              arguments: email,
            );
          }),
        );
      },
    );
  }

  Future<void> _handleAuthState(AuthState state) async {
    if (!mounted) return;
    final AuthChangeEvent event = state.event;
    final User? user = state.session?.user;
    if (user != null) _lastSignedInUserId = user.id;

    if (event == AuthChangeEvent.passwordRecovery) {
      _authNotice.setRecoveryInProgress(true);
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.resetPassword,
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (event == AuthChangeEvent.signedIn) {
      if (_authNotice.recoveryInProgress) return;
      if (user == null) return;
      final AuthCompletion result = await _authFlow.completeEmailSignIn(
        user: user,
      );
      if (!mounted) return;
      if (result.message != null) _showNotice(result.message!);
      if (!result.started) return;
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      _authNotice.setRecoveryInProgress(false);
      final String? userId = _lastSignedInUserId;
      if (userId != null) _authFlow.reset(userId);
      _lastSignedInUserId = null;
    }
  }

  void _handleAuthNotice() {
    final String? route = _authNotice.route;
    if (route == null || !mounted) return;
    final String? message = _authNotice.message;
    final Object? arguments = _authNotice.arguments;
    _authNotice.clear();
    if (message != null) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  void _showNotice(String message, {String? route, Object? arguments}) {
    if (!mounted) return;
    if (route != null) {
      _authNotice.show(message, route: route, arguments: arguments);
      return;
    }
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _authNotice.removeListener(_handleAuthNotice);
    _authSubscription?.cancel();
    _authNotice.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget app = ChangeNotifierProvider<AuthNotice>.value(
      value: _authNotice,
      child: Provider<AuthSessionFlow>.value(
        value: _authFlow,
        child: PlacesScope(
          repository: _repository,
          child: ChangeNotifierProvider<UserProfileRepository>.value(
            value: _userProfile,
            child: MaterialApp(
              title: 'SALGO APP',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              navigatorKey: _navigatorKey,
              scaffoldMessengerKey: _messengerKey,
              builder: (BuildContext context, Widget? child) =>
                  FavoritesSyncBridge(
                    notifier: _repository.syncMessage,
                    messengerKey: _messengerKey,
                    child: child ?? const SizedBox.shrink(),
                  ),
              initialRoute: _userProfile.isSignedIn
                  ? AppRoutes.home
                  : AppRoutes.login,
              routes: {
                AppRoutes.login: (_) => const LoginScreen(),
                AppRoutes.register: (_) => const RegisterScreen(),
                AppRoutes.checkEmail: (_) => const CheckEmailScreen(),
                AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
                AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
                AppRoutes.home: (_) => const HomeScreen(),
                AppRoutes.preferences: (_) => const PreferencesScreen(),
                AppRoutes.detail: (_) => const DetailScreen(),
                AppRoutes.editProfile: (_) => const EditProfileScreen(),
                AppRoutes.notifications: (_) => const NotificationsScreen(),
                AppRoutes.placeDetail: (_) => const DetailScreen(),
              },
            ),
          ),
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
