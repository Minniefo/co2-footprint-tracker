import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Activity {
  final String id;
  final String userId;
  final String type;
  final Timestamp createdAt;
  final String source;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    this.source = 'manual',
  });

  double get co2Kg;
  String get activityType => type;

  Map<String, dynamic> toMap();

  factory Activity.fromMap(String id, Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'transport':
        return TransportActivity.fromMap(id, map);
      case 'food':
        return FoodActivity.fromMap(id, map);
      case 'energy':
        return EnergyActivity.fromMap(id, map);
      default:
        throw Exception('Unknown activity type: $type');
    }
  }
}

class TransportActivity extends Activity {
  final String transportMode;
  final String? startArea;
  final String? endArea;
  final double? distanceKm;
  final double co2Kg;
  final String? mapboxRouteId;
  final Map<String, dynamic>? privacy;

  TransportActivity({
    required super.id,
    required super.userId,
    super.type = 'transport',
    required this.transportMode,
    this.startArea,
    this.endArea,
    this.distanceKm,
    required this.co2Kg,
    this.mapboxRouteId,
    this.privacy,
    required super.createdAt,
    super.source,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'transport_mode': transportMode,
      if (startArea != null) 'start_area': startArea,
      if (endArea != null) 'end_area': endArea,
      if (distanceKm != null) 'distance_km': distanceKm,
      'co2_kg': co2Kg,
      if (mapboxRouteId != null) 'mapbox_route_id': mapboxRouteId,
      if (privacy != null) 'privacy': privacy,
      'created_at': createdAt,
      'source': source,
    };
  }

  factory TransportActivity.fromMap(String id, Map<String, dynamic> map) {
    return TransportActivity(
      id: id,
      userId: map['user_id'] as String,
      transportMode: map['transport_mode'] as String,
      startArea: map['start_area'] as String?,
      endArea: map['end_area'] as String?,
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      co2Kg: (map['co2_kg'] as num).toDouble(),
      mapboxRouteId: map['mapbox_route_id'] as String?,
      privacy: map['privacy'] as Map<String, dynamic>?,
      createdAt: map['created_at'] as Timestamp,
      source: map['source'] as String? ?? 'manual',
    );
  }
}

class FoodActivity extends Activity {
  final String foodCategory;
  final int servings;
  final double co2Kg;

  FoodActivity({
    required super.id,
    required super.userId,
    super.type = 'food',
    required this.foodCategory,
    this.servings = 1,
    required this.co2Kg,
    required super.createdAt,
    super.source,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'food_category': foodCategory,
      'servings': servings,
      'co2_kg': co2Kg,
      'created_at': createdAt,
      'source': source,
    };
  }

  factory FoodActivity.fromMap(String id, Map<String, dynamic> map) {
    return FoodActivity(
      id: id,
      userId: map['user_id'] as String,
      foodCategory: map['food_category'] as String,
      servings: map['servings'] as int? ?? 1,
      co2Kg: (map['co2_kg'] as num).toDouble(),
      createdAt: map['created_at'] as Timestamp,
      source: map['source'] as String? ?? 'manual',
    );
  }
}

class EnergyActivity extends Activity {
  final String energyType;
  final double kwh;
  final double co2Kg;

  EnergyActivity({
    required super.id,
    required super.userId,
    super.type = 'energy',
    required this.energyType,
    required this.kwh,
    required this.co2Kg,
    required super.createdAt,
    super.source,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'energy_type': energyType,
      'kwh': kwh,
      'co2_kg': co2Kg,
      'created_at': createdAt,
      'source': source,
    };
  }

  factory EnergyActivity.fromMap(String id, Map<String, dynamic> map) {
    return EnergyActivity(
      id: id,
      userId: map['user_id'] as String,
      energyType: map['energy_type'] as String,
      kwh: (map['kwh'] as num).toDouble(),
      co2Kg: (map['co2_kg'] as num).toDouble(),
      createdAt: map['created_at'] as Timestamp,
      source: map['source'] as String? ?? 'manual',
    );
  }
}
