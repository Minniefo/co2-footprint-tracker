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
      final doc = await collection.doc(cacheKey).get();
      if (doc.exists) {
        final data = doc.data()!;
        final geometry = (data['geometry'] as List?)?.map((p) => LatLng(p['lat'], p['lng'])).toList() ?? [];
        
        return RouteInfo(
          distanceKm: (data['distance_km'] as num).toDouble(),
          durationS: (data['duration_s'] as num).toInt(),
          startAreaName: data['start_area_name'] as String?,
          endAreaName: data['end_area_name'] as String?,
          polyline: geometry,
        );
      }
    } catch (e) {
      // Fallback
    }

    // Use geometries=geojson to get coordinates directly
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$mode/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=${MapboxConfig.publicToken}'
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    final data = json.decode(response.body);
    if ((data['routes'] as List).isEmpty) {
      throw Exception('No valid route found');
    }

    final route = data['routes'][0];
    final distanceKm = double.parse(((route['distance'] as num) / 1000).toStringAsFixed(2));
    final durationS = (route['duration'] as num).toInt();
    
    // Parse GeoJSON geometry
    final List<dynamic> coordinates = route['geometry']['coordinates'];
    final List<LatLng> polyline = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

    try {
      await collection.doc(cacheKey).set({
        'cache_key': cacheKey,
        'distance_km': distanceKm,
        'duration_s': durationS,
        'geometry': polyline.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {}

    return RouteInfo(
      distanceKm: distanceKm,
      durationS: durationS,
      polyline: polyline,
    );
  }

  /// Fetches location suggestions as the user types
  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.length < 3) return [];
    
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=${MapboxConfig.publicToken}&autocomplete=true&limit=5'
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    final List features = data['features'] ?? [];

    return features.map((f) => {
      'text': f['place_name'] as String,
      'center': f['center'] as List, // [lng, lat]
    }).toList();
  }
}
