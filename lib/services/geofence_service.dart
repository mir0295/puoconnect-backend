import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeofenceService {
  // 📍 Koordinat Pusat Politeknik Ungku Omar (PUO)
  static const double puoLatitude = 4.5880;
  static const double puoLongitude = 101.1200;
  
  // 📏 Radius Geofence (500 Meter)
  static const double geofenceRadiusMeters = 500.0;

  /// Semak kebenaran GPS dan dapatkan lokasi semasa
  static Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Semak samada GPS peranti dibuka
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Menggunakan LocationSettings terkini (Menghilangkan warning deprecated)
return await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
  }

  /// Fungsi Utama: Semak samada User berada dalam radius 500m dari PUO
  static Future<bool> isUserInsidePUO() async {
    Position? position = await _getCurrentLocation();
    if (position == null) return false;

    // Kira jarak (dalam meter) antara lokasi user dan pusat PUO
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      puoLatitude,
      puoLongitude,
    );

    debugPrint("📏 Jarak User dari PUO: ${distanceInMeters.toStringAsFixed(2)} Meter");

    // Pulangkan TRUE jika jarak <= 500 meter
    return distanceInMeters <= geofenceRadiusMeters;
  }

  /// ➕ FUNGSI TAMBAHAN: Dapatkan jarak (dalam meter/km) dari PUO
  static Future<double?> getDistanceToPUO() async {
    Position? position = await _getCurrentLocation();
    if (position == null) return null;

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      puoLatitude,
      puoLongitude,
    );
  }
}