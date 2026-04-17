import 'dart:math';

class LocationUtils {
  LocationUtils._();

  /// Distance in meters between two lat/lng points (Haversine)
  static double distanceInMeters(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  static bool isWithin2km(
    double issueLat, double issueLng,
    double userLat, double userLng,
  ) {
    return distanceInMeters(issueLat, issueLng, userLat, userLng) <= 2000;
  }
}
