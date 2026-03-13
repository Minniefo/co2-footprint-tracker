import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/activity_provider.dart';

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
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'Transport'),
            Tab(icon: Icon(Icons.restaurant), text: 'Food'),
            Tab(icon: Icon(Icons.bolt), text: 'Energy'),
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
  String _transportMode = 'car';
  final _distanceController = TextEditingController();

  final List<String> _modes = [
    'car',
    'bus',
    'train',
    'flight_short',
    'flight_long',
    'bike',
    'walk',
  ];

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(activityControllerProvider.notifier).logTransportActivity(
            transportMode: _transportMode,
            distanceKm: double.parse(_distanceController.text),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transport activity logged!')),
        );
        _distanceController.clear();
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _transportMode,
              decoration: const InputDecoration(
                labelText: 'Transport Mode',
                border: OutlineInputBorder(),
              ),
              items: _modes.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _transportMode = val);
                }
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance (km)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter distance';
                if (double.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Log Transport Activity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
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
  String _foodCategory = 'meat_meal';
  final _servingsController = TextEditingController(text: '1');

  final List<String> _categories = [
    'meat_meal',
    'vegetarian_meal',
    'vegan_meal',
  ];

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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _foodCategory,
              decoration: const InputDecoration(
                labelText: 'Food Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.replaceAll('_', ' ').toUpperCase()),
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
              decoration: const InputDecoration(
                labelText: 'Servings',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter servings';
                if (int.tryParse(value) == null) return 'Enter valid integer';
                return null;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Log Food Activity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
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
  String _energyType = 'electricity';
  final _kwhController = TextEditingController();

  final List<String> _types = [
    'electricity',
    'gas',
  ];

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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _energyType,
              decoration: const InputDecoration(
                labelText: 'Energy Type',
                border: OutlineInputBorder(),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
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
              decoration: const InputDecoration(
                labelText: 'Usage (kWh)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter kWh';
                if (double.tryParse(value) == null) return 'Enter valid number';
                return null;
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Log Energy Usage',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
