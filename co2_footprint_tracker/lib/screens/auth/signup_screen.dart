import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/auth_state.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _householdSizeCtrl = TextEditingController();

  String? _homeType;
  String? _dietType;
  String? _preferredTransport;

  bool _obscure1 = true;
  bool _obscure2 = true;
  int _step = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _displayNameCtrl.dispose();
    _countryCtrl.dispose();
    _householdSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_step2Key.currentState!.validate()) return;

    final userData = UserModel(
      displayName: _displayNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      country: _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : null,
      homeType: _homeType,
      dietType: _dietType,
      householdSize: int.tryParse(_householdSizeCtrl.text.trim()),
      preferredTransport: _preferredTransport,
    );

    final ok = await ref.read(authControllerProvider.notifier).registerWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          userData: userData,
        );

    if (!mounted) return;

    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Registration failed')),
      );
    }
  }

  void _goToStep2() {
    if (!_step1Key.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Header ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.green, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text('Create Account', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text('Join and start tracking your CO₂ footprint', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Step Indicator ──────────────────────────────────
              Row(
                children: [
                  _StepDot(index: 1, label: 'Account', active: _step == 0, done: _step > 0),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: _step > 0 ? Colors.green : Colors.grey.shade200,
                    ),
                  ),
                  _StepDot(index: 2, label: 'Eco Profile', active: _step == 1, done: false),
                ],
              ),

              const SizedBox(height: 36),

              // ── Animated Form Steps ─────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _step == 0
                    ? _buildStep1()
                    : _buildStep2(authState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 1: Account Details ────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Email Address'),
          _field(controller: _emailCtrl, hint: 'you@example.com', keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null),
          const SizedBox(height: 16),

          _label('Password'),
          _field(controller: _passwordCtrl, hint: '••••••••', isPassword: true, obscure: _obscure1,
            onToggle: () => setState(() => _obscure1 = !_obscure1),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            }),
          const SizedBox(height: 16),

          _label('Confirm Password'),
          _field(controller: _confirmPasswordCtrl, hint: '••••••••', isPassword: true, obscure: _obscure2,
            onToggle: () => setState(() => _obscure2 = !_obscure2),
            validator: (v) => (v == null || v.isEmpty) ? 'Please confirm your password' : null),
          const SizedBox(height: 16),

          _label('Display Name'),
          _field(controller: _displayNameCtrl, hint: 'How others see you',
            validator: (v) => (v == null || v.isEmpty) ? 'Display name is required' : null),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Next: Eco Profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(text: 'Login', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── STEP 2: Eco Profile ────────────────────────────────────────────────
  Widget _buildStep2(AuthState authState) {
    return Form(
      key: _step2Key,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Country (optional)'),
          _field(controller: _countryCtrl, hint: 'e.g. UK'),
          const SizedBox(height: 16),

          _label('Home Type (optional)'),
          _dropdown(
            value: _homeType, hint: 'Select home type',
            items: const [
              DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
              DropdownMenuItem(value: 'house', child: Text('House')),
              DropdownMenuItem(value: 'condo', child: Text('Condo')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _homeType = v),
          ),
          const SizedBox(height: 16),

          _label('Diet Type (optional)'),
          _dropdown(
            value: _dietType, hint: 'Select your diet',
            items: const [
              DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
              DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
              DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
              DropdownMenuItem(value: 'pescatarian', child: Text('Pescatarian')),
            ],
            onChanged: (v) => setState(() => _dietType = v),
          ),
          const SizedBox(height: 16),

          _label('Household Size (optional)'),
          _field(controller: _householdSizeCtrl, hint: 'Number of people', keyboardType: TextInputType.number,
            validator: (v) {
              if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Enter a valid number';
              return null;
            }),
          const SizedBox(height: 16),

          _label('Preferred Transport (optional)'),
          _dropdown(
            value: _preferredTransport, hint: 'How do you mostly travel?',
            items: const [
              DropdownMenuItem(value: 'car', child: Text('Car')),
              DropdownMenuItem(value: 'public_transport', child: Text('Public Transport')),
              DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
              DropdownMenuItem(value: 'walking', child: Text('Walking')),
              DropdownMenuItem(value: 'electric_vehicle', child: Text('Electric Vehicle')),
            ],
            onChanged: (v) => setState(() => _preferredTransport = v),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text('Back', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: authState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Create Account', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade500), onPressed: onToggle)
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: GoogleFonts.inter(color: Colors.grey.shade400)),
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        ),
        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({required this.index, required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (active || done) ? Colors.green : Colors.grey.shade200,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$index',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey.shade400),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.green : Colors.grey.shade400)),
      ],
    );
  }
}