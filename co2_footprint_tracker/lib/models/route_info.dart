class RouteInfo {
  final double distanceKm;
  final int durationS;
  final String? startAreaName;
  final String? endAreaName;

  RouteInfo({
    required this.distanceKm,
    required this.durationS,
    this.startAreaName,
    this.endAreaName,
  });
}
