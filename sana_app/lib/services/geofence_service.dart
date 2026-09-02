import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/geofence_zone.dart';

class GeofenceService {
  static final GeofenceService instance = GeofenceService._internal();
  final NetworkInfo _networkInfo = NetworkInfo();
  
  List<GeofenceZone> zones = [
    GeofenceZone(id: '1', name: 'Home', wifiSsid: 'Home_WiFi'),
    GeofenceZone(id: '2', name: 'Work', wifiSsid: 'Office_WiFi'),
  ];

  GeofenceService._internal();

  Future<String> determineCurrentZone() async {
    try {
      // 1. Check Wi-Fi SSID for instant indoor zone recognition
      final wifiName = await _networkInfo.getWifiName();
      if (wifiName != null && wifiName.isNotEmpty) {
        final cleanSsid = wifiName.replaceAll('"', '').trim();
        for (var zone in zones) {
          if (zone.wifiSsid != null &&
              zone.wifiSsid!.isNotEmpty &&
              cleanSsid.toLowerCase() == zone.wifiSsid!.toLowerCase()) {
            return zone.name;
          }
        }
      }

      // 2. Check GPS coordinates
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 3),
              ),
            );
          } catch (_) {
            position = null;
          }

          if (position != null) {
            for (var zone in zones) {
              if (zone.latitude != null && zone.longitude != null) {
                double distance = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  zone.latitude!,
                  zone.longitude!,
                );
                if (distance <= zone.radiusMeters) {
                  return zone.name;
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // Fallback on error
    }
    return 'Street/Other';
  }

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  double getEnvironmentalMultiplier(String zone, String soundClass) {
    // Street / Urban context: boost siren, honking, brake squeal
    if (zone == 'Street/Other') {
      if (soundClass.contains('Siren') || soundClass.contains('Horn') || soundClass.contains('Brake')) {
        return 2.5;
      }
      return 1.2;
    }
    
    // Home context: boost door knock, baby cry, smoke detector, fire alarm
    if (zone == 'Home') {
      if (soundClass.contains('Fire') || soundClass.contains('Smoke') || soundClass.contains('Baby') || soundClass.contains('Door')) {
        return 2.2;
      }
      return 1.0;
    }

    // Work context
    if (zone == 'Work') {
      if (soundClass.contains('Fire') || soundClass.contains('Alarm') || soundClass.contains('Screaming')) {
        return 2.2;
      }
      return 1.0;
    }

    return 1.0;
  }
}
