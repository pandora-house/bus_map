import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocatorController {
  Future<Stream<Position>> getPositionUser() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    return _checkLocationPermission().then(
      (_) => Geolocator.getPositionStream(locationSettings: locationSettings),
    );
  }

  Future<void> _checkLocationPermission() async {
    late LocationPermission permission;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  Future<Position?> getLastKnownPosition() async {
    return _requestLocationPermission().then(
          (_) => Geolocator.getLastKnownPosition(),
    );
  }

  Future<void> _requestLocationPermission() async {
    late LocationPermission permission;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      await Geolocator.openLocationSettings();
      return Future.error('Location permissions are denied');
    }
  }
}
