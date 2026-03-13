import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/mapbox_config.dart';
import '../models/route_info.dart';

class MapboxService {
  final FirebaseFirestore _firestore;

  MapboxService(this._firestore);

  // Helper to round degrees for cache key grouping to 3 decimal places (approx 100m radius)
  String _round(double val) => val.toStringAsFixed(3);

  Future<RouteInfo> getRoute(LatLng start, LatLng end, {String mode = 'driving'}) async {
    final cacheKey = '${_round(start.latitude)}_${_round(start.longitude)}_${_round(end.latitude)}_${_round(end.longitude)}_$mode';
    final collection = _firestore.collection('map_cache');
    
    try {
      // 1. Check Cache
      final doc = await collection.doc(cacheKey).get();
      if (doc.exists) {
        final data = doc.data()!;
        return RouteInfo(
          distanceKm: (data['distance_km'] as num).toDouble(),
          durationS: (data['duration_s'] as num).toInt(),
          startAreaName: data['start_area_name'] as String?,
          endAreaName: data['end_area_name'] as String?,
        );
      }
    } catch (e) {
      // Ignore cache read failures and fallback to API
    }

    // 2. Fetch from Mapbox Directions API
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$mode/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?access_token=${MapboxConfig.publicToken}'
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route. Check Mapbox token and network.');
    }

    final data = json.decode(response.body);
    if ((data['routes'] as List).isEmpty) {
      throw Exception('No valid route found');
    }

    final route = data['routes'][0];
    final distanceMeters = (route['distance'] as num).toDouble();
    final distanceKm = double.parse((distanceMeters / 1000).toStringAsFixed(2));
    final durationS = (route['duration'] as num).toInt();

    // 3. Save to Cache
    try {
      await collection.doc(cacheKey).set({
        'cache_key': cacheKey,
        'distance_km': distanceKm,
        'duration_s': durationS,
        'start_area_name': null, // Expandable with reverse-geocoding later
        'end_area_name': null,
        'created_at': FieldValue.serverTimestamp(),
        'fetched_from': 'mapbox',
      });
    } catch (e) {
      // Ignore cache write failures
    }

    return RouteInfo(
      distanceKm: distanceKm,
      durationS: durationS,
    );
  }
}
