import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';

class GoogleOnboardingScreen extends ConsumerStatefulWidget {
  const GoogleOnboardingScreen({super.key});

  @override
  ConsumerState<GoogleOnboardingScreen> createState() => _GoogleOnboardingScreenState();
}

class _GoogleOnboardingScreenState extends ConsumerState<GoogleOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();

  String? _homeType;
  String? _dietType;
  String? _transport;
  bool _loading = false;

  @override
  void dispose() {
    _countryCtrl.dispose();
    _householdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userService = UserService(FirebaseFirestore.instance);

    // Build only the fields the user provided — skip nulls
    final data = <String, dynamic>{};
    if (_countryCtrl.text.trim().isNotEmpty) data['country'] = _countryCtrl.text.trim();
    if (_homeType != null) data['home_type'] = _homeType;
    if (_dietType != null) data['diet_type'] = _dietType;
    if (_transport != null) data['preferred_transport'] = _transport;
    if (_householdCtrl.text.trim().isNotEmpty) {
      data['household_size'] = int.tryParse(_householdCtrl.text.trim());
    }

    if (data.isNotEmpty) {
      await userService.updateAdditionalDetails(uid, data);
    }
    await userService.setOnboardingComplete(uid);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _skip() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserService(FirebaseFirestore.instance).setOnboardingComplete(uid);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.eco_rounded, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('One last step! 🌱', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('Tell us about your eco lifestyle', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _skip,
                      child: Text('Skip', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Container(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 28),

                Text('All fields are optional — you can also update these later in your profile.', 
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 24),

                // ── Fields ──────────────────────────────────────────
                _label('Country'),
                _field(controller: _countryCtrl, hint: 'e.g. UK'),
                const SizedBox(height: 16),

                _label('Home Type'),
                _dropdown(value: _homeType, hint: 'Select home type',
                  items: const [
                    DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                    DropdownMenuItem(value: 'house', child: Text('House')),
                    DropdownMenuItem(value: 'condo', child: Text('Condo')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _homeType = v),
                ),
                const SizedBox(height: 16),

                _label('Diet Type'),
                _dropdown(value: _dietType, hint: 'Select your diet',
                  items: const [
                    DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                    DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                    DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                    DropdownMenuItem(value: 'pescatarian', child: Text('Pescatarian')),
                  ],
                  onChanged: (v) => setState(() => _dietType = v),
                ),
                const SizedBox(height: 16),

                _label('Household Size'),
                _field(controller: _householdCtrl, hint: 'Number of people', keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  }),
                const SizedBox(height: 16),

                _label('Preferred Transport'),
                _dropdown(value: _transport, hint: 'How do you mostly travel?',
                  items: const [
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'public_transport', child: Text('Public Transport')),
                    DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                    DropdownMenuItem(value: 'walking', child: Text('Walking')),
                    DropdownMenuItem(value: 'electric_vehicle', child: Text('Electric Vehicle')),
                  ],
                  onChanged: (v) => setState(() => _transport = v),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text("Let's Go! 🌿", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
  );

  Widget _field({required TextEditingController controller, required String hint,
    TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown({required String? value, required String hint,
    required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: GoogleFonts.inter(color: Colors.grey.shade400)),
        items: items,
        onChanged: onChanged,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4)),
        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      ),
    );
  }
}
