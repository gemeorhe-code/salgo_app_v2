import 'package:flutter/widgets.dart';

import 'places_repository.dart';

class PlacesScope extends InheritedNotifier<PlacesRepository> {
  const PlacesScope({
    super.key,
    required PlacesRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static PlacesRepository of(BuildContext context) {
    final PlacesScope? scope = context
        .dependOnInheritedWidgetOfExactType<PlacesScope>();
    assert(scope != null, 'PlacesScope no encontrado en el árbol de widgets.');
    return scope!.notifier!;
  }
}
