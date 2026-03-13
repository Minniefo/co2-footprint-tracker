import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emission_factors.dart';

class EmissionFactorsService {
  final FirebaseFirestore _firestore;

  EmissionFactorsService(this._firestore);

  Future<EmissionFactors> getEmissionFactors() async {
    try {
      final doc = await _firestore.collection('settings').doc('emission_factors').get();
      if (!doc.exists || doc.data() == null) {
        // Return default factors if not found
        return EmissionFactors(transport: {
          'car': 0.170,
          'bus': 0.089,
          'train': 0.041,
          'flight_short': 0.255,
          'flight_long': 0.150,
          'bike': 0.0,
          'walk': 0.0,
        });
      }
      return EmissionFactors.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to fetch emission factors: $e');
    }
  }
}
