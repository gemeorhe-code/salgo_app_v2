import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salgo_app/widgets/favorites_sync_bridge.dart';

void main() {
  testWidgets('El bridge muestra el SnackBar de sincronización', (
    WidgetTester tester,
  ) async {
    final GlobalKey<ScaffoldMessengerState> key =
        GlobalKey<ScaffoldMessengerState>();
    final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: FavoritesSyncBridge(
          notifier: notifier,
          messengerKey: key,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    notifier.value = 'No se pudieron sincronizar tus favoritos.';
    await tester.pump();

    expect(
      find.text('No se pudieron sincronizar tus favoritos.'),
      findsOneWidget,
    );
    expect(notifier.value, isNull);

    notifier.dispose();
  });
}
