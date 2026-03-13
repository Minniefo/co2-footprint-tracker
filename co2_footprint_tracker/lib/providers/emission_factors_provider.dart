import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emission_factors.dart';
import '../services/emission_factors_service.dart';
import 'auth_provider.dart';

final emissionFactorsServiceProvider = Provider<EmissionFactorsService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return EmissionFactorsService(firestore);
});

final emissionFactorsProvider = FutureProvider<EmissionFactors>((ref) async {
  final service = ref.watch(emissionFactorsServiceProvider);
  return service.getEmissionFactors();
});
