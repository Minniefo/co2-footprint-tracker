class EmissionFactors {
  final Map<String, double> transport;
  final Map<String, double> food;
  final Map<String, double> energy;

  EmissionFactors({
    required this.transport,
    required this.food,
    required this.energy,
  });

  factory EmissionFactors.fromMap(Map<String, dynamic> map) {
    return EmissionFactors(
      transport: _parseMap(map['transport']),
      food: _parseMap(map['food']),
      energy: _parseMap(map['energy']),
    );
  }

  static Map<String, double> _parseMap(dynamic data) {
    if (data == null || data is! Map) return {};
    final result = <String, double>{};
    data.forEach((key, value) {
      result[key.toString()] = (value as num).toDouble();
    });
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'transport': transport,
      'food': food,
      'energy': energy,
    };
  }

  double getTransportFactor(String mode) => transport[mode] ?? 0.0;
  double getFoodFactor(String category) => food[category] ?? 0.0;
  double getEnergyFactor(String type) => energy[type] ?? 0.0;
}
