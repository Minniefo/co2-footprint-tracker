import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../providers/activity_provider.dart';
import '../../providers/mapbox_provider.dart';
import '../../services/co2_calculator.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  const AddActivityScreen({super.key});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Log Activity',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green.shade700,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.directions_car_rounded), text: 'Transport'),
            Tab(icon: Icon(Icons.restaurant_rounded), text: 'Food'),
            Tab(icon: Icon(Icons.bolt_rounded), text: 'Energy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TransportActivityForm(),
          FoodActivityForm(),
          EnergyActivityForm(),
        ],
      ),
    );
  }
}

class TransportActivityForm extends ConsumerStatefulWidget {
  const TransportActivityForm({super.key});

  @override
  ConsumerState<TransportActivityForm> createState() => _TransportActivityFormState();
}

class _TransportActivityFormState extends ConsumerState<TransportActivityForm> {
  final _formKey = GlobalKey<FormState>();
  String _transportMode = 'car_petrol';
  final _distanceController = TextEditingController();

  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _isCalculatingRoute = false;
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(51.5074, -0.1278); // London default

  final List<Map<String, String>> _modes = [
    {'value': 'car_petrol', 'label': 'Petrol Car', 'icon': '🚗'},
    {'value': 'car_diesel', 'label': 'Diesel Car', 'icon': '🚙'},
    {'value': 'car_ev', 'label': 'Electric Car', 'icon': '⚡'},
    {'value': 'bus', 'label': 'Bus', 'icon': '🚌'},
    {'value': 'train', 'label': 'Train', 'icon': '🚆'},
    {'value': 'flight_short', 'label': 'Short Flight (<3h)', 'icon': '✈️'},
    {'value': 'flight_long', 'label': 'Long Flight (>3h)', 'icon': '🗺️'},
    {'value': 'bike', 'label': 'Bicycle', 'icon': '🚲'},
    {'value': 'walk', 'label': 'Walking', 'icon': '🚶'},
  ];

  @override
  void initState() {
    super.initState();
    _distanceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) async {
    if (_startLocation == null) {
      setState(() {
        _startLocation = point;
        _endLocation = null;
      });
    } else if (_endLocation == null) {
      setState(() {
        _endLocation = point;
      });
      await _calculateRoute();
    } else {
      setState(() {
        _startLocation = point;
        _endLocation = null;
        _distanceController.clear();
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_startLocation == null || _endLocation == null) return;
    
    setState(() => _isCalculatingRoute = true);

    try {
      final service = ref.read(mapboxServiceProvider);
      String mapboxMode = 'driving';
      if (_transportMode == 'walk') mapboxMode = 'walking';
      if (_transportMode == 'bike') mapboxMode = 'cycling';

      final routeInfo = await service.getRoute(_startLocation!, _endLocation!, mode: mapboxMode);
      
      setState(() {
        _distanceController.text = routeInfo.distanceKm.toStringAsFixed(1);
        _isCalculatingRoute = false;
      });
    } catch (e) {
      setState(() => _isCalculatingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to calculate route: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(activityControllerProvider.notifier).logTransportActivity(
            transportMode: _transportMode,
            distanceKm: double.parse(_distanceController.text),
            startArea: _startLocation != null ? '${_startLocation!.latitude.toStringAsFixed(3)}, ${_startLocation!.longitude.toStringAsFixed(3)}' : null,
            endArea: _endLocation != null ? '${_endLocation!.latitude.toStringAsFixed(3)}, ${_endLocation!.longitude.toStringAsFixed(3)}' : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transport activity logged!')),
        );
        setState(() {
          _distanceController.clear();
          _startLocation = null;
          _endLocation = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityControllerProvider);
    final isLoading = activityState is AsyncLoading;
    final calcAsync = ref.watch(co2CalculatorProvider);

    return calcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading calculator: $err')),
      data: (calc) {
        final dist = double.tryParse(_distanceController.text) ?? 0.0;
        final currentCo2 = calc.calculateTransport(_transportMode, dist);
        final impact = calc.getImpactLevel(currentCo2);

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _transportMode,
                  decoration: InputDecoration(
                    labelText: 'Transport Mode',
                    labelStyle: GoogleFonts.inter(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _modes.map((mode) {
                    return DropdownMenuItem(
                      value: mode['value'],
                      child: Text('${mode['icon']} ${mode['label']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _transportMode = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Select Route (Tap Start & End)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _defaultCenter,
                        initialZoom: 12.0,
                        onTap: _handleMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.co2_footprint_tracker',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_startLocation != null)
                              Marker(
                                point: _startLocation!,
                                width: 30,
                                height: 30,
                                child: const Icon(Icons.location_on, color: Colors.green, size: 30),
                              ),
                            if (_endLocation != null)
                              Marker(
                                point: _endLocation!,
                                width: 30,
                                height: 30,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isCalculatingRoute)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Distance (km)',
                    hintText: 'Enter or use map above',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter distance';
                    final d = double.tryParse(value);
                    if (d == null) return 'Enter valid number';
                    if (d <= 0 && _transportMode != 'walk' && _transportMode != 'bike') return 'Distance must be > 0';
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                
                // Impact Preview
                _ImpactPreview(co2Kg: currentCo2, level: impact),

                const Spacer(),
                ElevatedButton(
                  onPressed: isLoading || _isCalculatingRoute ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Log Transport Activity',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FoodActivityForm extends ConsumerStatefulWidget {
  const FoodActivityForm({super.key});

  @override
  ConsumerState<FoodActivityForm> createState() => _FoodActivityFormState();
}

class _FoodActivityFormState extends ConsumerState<FoodActivityForm> {
  final _formKey = GlobalKey<FormState>();
  String _foodCategory = 'meat_beef';
  final _servingsController = TextEditingController(text: '1');

  final List<Map<String, String>> _categories = [
    {'value': 'meat_beef', 'label': 'Beef / Lamb', 'icon': '🥩'},
    {'value': 'meat_pork', 'label': 'Pork', 'icon': '🥓'},
    {'value': 'meat_chicken', 'label': 'Poultry', 'icon': '🍗'},
    {'value': 'fish', 'label': 'Fish', 'icon': '🐟'},
    {'value': 'dairy', 'label': 'Dairy / Eggs', 'icon': '🥚'},
    {'value': 'vegetarian', 'label': 'Vegetarian Meal', 'icon': '🥗'},
    {'value': 'vegan', 'label': 'Vegan Meal', 'icon': '🌱'},
  ];

  @override
  void initState() {
    super.initState();
    _servingsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(activityControllerProvider.notifier).logFoodActivity(
            foodCategory: _foodCategory,
            servings: int.parse(_servingsController.text),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food activity logged!')),
        );
        _servingsController.text = '1';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityControllerProvider);
    final isLoading = activityState is AsyncLoading;
    final calcAsync = ref.watch(co2CalculatorProvider);

    return calcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading calculator: $err')),
      data: (calc) {
        final servings = int.tryParse(_servingsController.text) ?? 0;
        final currentCo2 = calc.calculateFood(_foodCategory, servings);
        final impact = calc.getImpactLevel(currentCo2);

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _foodCategory,
                  decoration: InputDecoration(
                    labelText: 'Food Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['value'],
                      child: Text('${cat['icon']} ${cat['label']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _foodCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _servingsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Servings',
                    hintText: 'Number of plates/portions',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter servings';
                    final s = int.tryParse(value);
                    if (s == null) return 'Enter valid integer';
                    if (s <= 0) return 'Servings must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _ImpactPreview(co2Kg: currentCo2, level: impact),
                const Spacer(),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Log Food Activity',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EnergyActivityForm extends ConsumerStatefulWidget {
  const EnergyActivityForm({super.key});

  @override
  ConsumerState<EnergyActivityForm> createState() => _EnergyActivityFormState();
}

class _EnergyActivityFormState extends ConsumerState<EnergyActivityForm> {
  final _formKey = GlobalKey<FormState>();
  String _energyType = 'electricity_grid';
  final _kwhController = TextEditingController();

  final List<Map<String, String>> _types = [
    {'value': 'electricity_grid', 'label': 'Grid Electricity', 'icon': '🔌'},
    {'value': 'electricity_renewable', 'label': 'Renewable Energy', 'icon': '☀️'},
    {'value': 'natural_gas', 'label': 'Natural Gas', 'icon': '🔥'},
    {'value': 'heating_oil', 'label': 'Heating Oil', 'icon': '🛢️'},
  ];

  @override
  void initState() {
    super.initState();
    _kwhController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _kwhController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(activityControllerProvider.notifier).logEnergyActivity(
            energyType: _energyType,
            kwh: double.parse(_kwhController.text),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Energy activity logged!')),
        );
        _kwhController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityState = ref.watch(activityControllerProvider);
    final isLoading = activityState is AsyncLoading;
    final calcAsync = ref.watch(co2CalculatorProvider);

    return calcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading calculator: $err')),
      data: (calc) {
        final kwh = double.tryParse(_kwhController.text) ?? 0.0;
        final currentCo2 = calc.calculateEnergy(_energyType, kwh);
        final impact = calc.getImpactLevel(currentCo2);

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _energyType,
                  decoration: InputDecoration(
                    labelText: 'Energy Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text('${type['icon']} ${type['label']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _energyType = val);
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _kwhController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Usage (kWh)',
                    hintText: 'Check your utility bill',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter kWh';
                    final k = double.tryParse(value);
                    if (k == null) return 'Enter valid number';
                    if (k <= 0) return 'kWh must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _ImpactPreview(co2Kg: currentCo2, level: impact),
                const Spacer(),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Log Energy Usage',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImpactPreview extends StatelessWidget {
  final double co2Kg;
  final ImpactLevel level;

  const _ImpactPreview({required this.co2Kg, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (level) {
      case ImpactLevel.low:
        color = Colors.green;
        text = 'Low Impact';
        icon = Icons.eco_rounded;
      case ImpactLevel.medium:
        color = Colors.orange;
        text = 'Medium Impact';
        icon = Icons.info_outline;
      case ImpactLevel.high:
        color = Colors.red;
        text = 'High Impact';
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Footprint',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${co2Kg.toStringAsFixed(2)} kg CO₂',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
