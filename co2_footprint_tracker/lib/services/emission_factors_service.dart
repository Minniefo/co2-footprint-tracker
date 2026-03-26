import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emission_factors.dart';

class EmissionFactorsService {
  final FirebaseFirestore _firestore;

  EmissionFactorsService(this._firestore);

  Future<EmissionFactors> getEmissionFactors() async {
    final defaults = EmissionFactors(
      transport: {
        'car_petrol': 0.180,
        'car_diesel': 0.170,
        'car_ev': 0.050,
        'bus': 0.089,
        'train': 0.035,
        'flight_short': 0.255,
        'flight_long': 0.150,
        'bike': 0.0,
        'walk': 0.0,
      },
      food: {
        'meat_beef': 6.5,
        'meat_pork': 1.8,
        'meat_chicken': 1.5,
        'fish': 1.2,
        'dairy': 1.1,
        'vegetarian': 0.8,
        'vegan': 0.5,
      },
      energy: {
        'electricity_grid': 0.45,
        'electricity_renewable': 0.05,
        'natural_gas': 0.20,
        'heating_oil': 0.26,
      },
    );

    try {
      final doc = await _firestore.collection('settings').doc('emission_factors').get();
      if (!doc.exists || doc.data() == null) {
        return defaults;
      }
      
      final data = doc.data()!;
      
      // Merge Firestore data with defaults
      return EmissionFactors(
        transport: {
          ...defaults.transport,
          ..._parseMap(data['transport']),
        },
        food: {
          ...defaults.food,
          ..._parseMap(data['food']),
        },
        energy: {
          ...defaults.energy,
          ..._parseMap(data['energy']),
        },
      );
    } catch (e) {
      // In case of error, return defaults rather than throwing
      return defaults;
    }
  }

  static Map<String, double> _parseMap(dynamic data) {
    if (data == null || data is! Map) return {};
    final result = <String, double>{};
    data.forEach((key, value) {
      if (value is num) {
        result[key.toString()] = value.toDouble();
      }
    });
    return result;
  }
}
