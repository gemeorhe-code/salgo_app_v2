import 'dart:async';

import 'package:geolocator/geolocator.dart';

abstract class LocationService {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<LocationCoordinates> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
  });

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<LocationCoordinates> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );
    return LocationCoordinates(position.latitude, position.longitude);
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

class LocationCoordinates {
  const LocationCoordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

sealed class LocationOutcome {
  const LocationOutcome();
}

class LocationGpsDisabled extends LocationOutcome {
  const LocationGpsDisabled();
}

class LocationPermissionDenied extends LocationOutcome {
  const LocationPermissionDenied();
}

class LocationPermissionDeniedForever extends LocationOutcome {
  const LocationPermissionDeniedForever();
}

class LocationTimeout extends LocationOutcome {
  const LocationTimeout();
}

class LocationFailure extends LocationOutcome {
  const LocationFailure();
}

class LocationSuccess extends LocationOutcome {
  const LocationSuccess(this.coordinates);

  final LocationCoordinates coordinates;
}

Future<LocationOutcome> resolveCurrentLocation(LocationService service) async {
  if (!await service.isLocationServiceEnabled()) {
    return const LocationGpsDisabled();
  }

  LocationPermission permission = await service.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await service.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    return const LocationPermissionDenied();
  }
  if (permission == LocationPermission.deniedForever) {
    return const LocationPermissionDeniedForever();
  }
  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    return const LocationFailure();
  }

  try {
    final LocationCoordinates coordinates = await service.getCurrentPosition();
    return LocationSuccess(coordinates);
  } on TimeoutException {
    return const LocationTimeout();
  } catch (_) {
    return const LocationFailure();
  }
}
