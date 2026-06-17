import 'dart:math' as math;

/// Calculates the distance in meters between two geographical points using the Haversine formula.
double haversineDistanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const double earthRadiusMeters = 6371000;

  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);

  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusMeters * c;
}

double _toRadians(double degree) {
  return degree * (math.pi / 180);
}
