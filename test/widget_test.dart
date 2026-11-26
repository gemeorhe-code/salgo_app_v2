import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:salgo_app/data/preferences_repository.dart';
import 'package:salgo_app/data/user_profile_repository.dart';
import 'package:salgo_app/main.dart';
import 'package:salgo_app/widgets/custom_dropdown.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.pumpWidget(const SalgoApp());
  await tester.pump();

  await tester.enterText(find.byType(TextFormField).first, 'demo@salgo.com');
  await tester.enterText(find.byType(TextFormField).last, '123456');
  await tester.tap(find.text('Ingresar'));
  await tester.pumpAndSettle();

  // Deja expirar el SnackBar de bienvenida para no tapar otros widgets.
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    UserProfileRepository.resetForTesting();
    PreferencesRepository.resetForTesting();
  });

  testWidgets('La pantalla de login se muestra al iniciar', (tester) async {
    await tester.pumpWidget(const SalgoApp());
    await tester.pump();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Registrarse aquí'), findsOneWidget);
  });

  testWidgets('El login valida campos vacíos', (tester) async {
    await tester.pumpWidget(const SalgoApp());
    await tester.pump();

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Por favor ingresa tu correo'), findsOneWidget);
    expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Flujo: login → home → categoría → preferencias → validación', (
    tester,
  ) async {
    await _login(tester);

    expect(find.text('Hola, Usuario'), findsOneWidget);
    expect(find.text('¿Qué plan hoy?'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Ver todo'), findsOneWidget);

    await tester.tap(find.text('Deportes'));
    await tester.pumpAndSettle();

    expect(find.text('Cuéntanos tus preferencias'), findsOneWidget);
    expect(find.text('Deportes'), findsWidgets);

    await tester.tap(find.text('LISTO'));
    await tester.pump();
    expect(find.text('Por favor selecciona con quién sales'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Preferencias: resumen y vuelta a home', (tester) async {
    await _login(tester);

    await tester.tap(find.text('Parques'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amigos'));
    await tester.pump();

    final Finder placeDropdown = find.byType(CustomDropdown).last;
    await tester.ensureVisible(placeDropdown);
    await tester.pumpAndSettle();

    await tester.tap(placeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Girón'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LISTO'));
    await tester.pumpAndSettle();

    expect(find.text('¡Listo!'), findsOneWidget);
    expect(find.text('Girón'), findsWidgets);
    expect(find.text('Amigos'), findsWidgets);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.text('Categorías'), findsOneWidget);
  });
}
