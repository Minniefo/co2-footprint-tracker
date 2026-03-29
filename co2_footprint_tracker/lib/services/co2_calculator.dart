import '../models/emission_factors.dart';

class Co2Calculator {
  final EmissionFactors factors;

  Co2Calculator(this.factors);

  double calculateTransport(String mode, double distanceKm) {
    if (distanceKm <= 0) return 0.0;
    final factor = factors.getTransportFactor(mode);
    // If factor is 0 but it's not a zero-emission mode, return a very small fallback
    if (factor <= 0 && mode != 'walk' && mode != 'bike') {
      return 0.01 * distanceKm; // Very low fallback
    }
    return factor * distanceKm;
  }

  double calculateFood(String category, int servings) {
    if (servings <= 0) return 0.0;
    final factor = factors.getFoodFactor(category);
    if (factor <= 0) return 0.05 * servings; // Fallback
    return factor * servings;
  }

  double calculateEnergy(String type, double kwh) {
    if (kwh <= 0) return 0.0;
    final factor = factors.getEnergyFactor(type);
    if (factor <= 0) return 0.1 * kwh; // Fallback
    return factor * kwh;
  }

  /// Categorizes impact level for UX feedback
  ImpactLevel getImpactLevel(double co2Kg) {
    if (co2Kg < 1.0) return ImpactLevel.low;
    if (co2Kg < 5.0) return ImpactLevel.medium;
    return ImpactLevel.high;
  }
}

enum ImpactLevel { low, medium, high }
