import 'package:latlong2/latlong.dart';

class RouteInfo {
  final double distanceKm;
  final int durationS;
  final String? startAreaName;
  final String? endAreaName;
  final List<LatLng> polyline;

  RouteInfo({
    required this.distanceKm,
    required this.durationS,
    this.startAreaName,
    this.endAreaName,
    this.polyline = const [],
  });
}
