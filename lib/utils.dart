import 'dart:math';

String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

String calculateAverageSpeed(double distanceInMeters, Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 5 || distanceInMeters < 5.0) return "0.00 km/h";
  final hours = seconds / 3600;
  final km = distanceInMeters / 1000;
  final speed = km / hours;
  return "${speed.toStringAsFixed(2)} km/h";
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _degToRad(double deg) => deg * (pi / 180);
