import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    final userData = UserModel(
      displayName: _displayNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER DESIGN
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "Create Account",
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              "Join and start tracking\nyour CO₂ footprint",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    /// EMAIL FIELD
                    _buildTextField(
                      controller: _emailCtrl,
                      hintText: "Email",
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD FIELD
                    _buildTextField(
                      controller: _passwordCtrl,
                      hintText: "Password",
                      isPassword: true,
                      obscureValue: _obscure1,
                      onToggle: () {
                        setState(() => _obscure1 = !_obscure1);
                      },
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM PASSWORD FIELD
                    _buildTextField(
                      controller: _confirmPasswordCtrl,
                      hintText: "Confirm Password",
                      isPassword: true,
                      obscureValue: _obscure2,
                      onToggle: () {
                        setState(() => _obscure2 = !_obscure2);
                      },
                    ),

                    const SizedBox(height: 20),

                    /// DISPLAY NAME FIELD
                    _buildTextField(
                      controller: _displayNameCtrl,
                      hintText: "Display Name",
                    ),

                    const SizedBox(height: 20),

                    /// COUNTRY FIELD
                    _buildTextField(
                      controller: _countryCtrl,
                      hintText: "Country",
                    ),

                    const SizedBox(height: 20),

                    /// HOME TYPE DROPDOWN
                    _buildDropdownField(
                      value: _homeType,
                      hintText: "Home Type",
                      items: const [
                        DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                        DropdownMenuItem(value: 'house', child: Text('House')),
                        DropdownMenuItem(value: 'condo', child: Text('Condo')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _homeType = value),
                    ),

                    const SizedBox(height: 20),

                    /// DIET TYPE DROPDOWN
                    _buildDropdownField(
                      value: _dietType,
                      hintText: "Diet Type",
                      items: const [
                        DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                        DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                        DropdownMenuItem(value: 'pescatarian', child: Text('Pescatarian')),
                      ],
                      onChanged: (value) => setState(() => _dietType = value),
                    ),

                    const SizedBox(height: 20),

                    /// HOUSEHOLD SIZE FIELD
                    _buildTextField(
                      controller: _householdSizeCtrl,
                      hintText: "Household Size",
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),

                    /// PREFERRED TRANSPORT DROPDOWN
                    _buildDropdownField(
                      value: _preferredTransport,
                      hintText: "Preferred Transport",
                      items: const [
                        DropdownMenuItem(value: 'car', child: Text('Car')),
                        DropdownMenuItem(value: 'public_transport', child: Text('Public Transport')),
                        DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                        DropdownMenuItem(value: 'walking', child: Text('Walking')),
                        DropdownMenuItem(value: 'electric_vehicle', child: Text('Electric Vehicle')),
                      ],
                      onChanged: (value) => setState(() => _preferredTransport = value),
                    ),

                    const SizedBox(height: 30),

                    /// SIGNUP BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: authState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Create Account",
                                style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),

                    const SizedBox(height: 25),

                    /// LOGIN LINK
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Already have an account? Login",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TEXT FIELD STYLE
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureValue = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscureValue : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureValue
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$hintText is required";
          }
          if (hintText == "Household Size" && int.tryParse(value) == null) {
            return "Please enter a valid number";
          }
          return null;
        },
      ),
    );
  }

  /// DROPDOWN FIELD STYLE
  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        hint: Text(hintText),
        items: items,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$hintText is required";
          }
          return null;
        },
      ),
    );
  }
}