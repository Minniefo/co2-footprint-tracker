class EmissionFactors {
  final Map<String, double> transport;

  EmissionFactors({
    required this.transport,
  });

  factory EmissionFactors.fromMap(Map<String, dynamic> map) {
    final transportMap = map['transport'] as Map<String, dynamic>? ?? {};
    final transport = <String, double>{};
    
    transportMap.forEach((key, value) {
      transport[key] = (value as num).toDouble();
    });

    return EmissionFactors(
      transport: transport,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transport': transport,
    };
  }

  double getTransportFactor(String mode) {
    return transport[mode] ?? 0.0;
  }
}
