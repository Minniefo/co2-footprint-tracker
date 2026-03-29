import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF8FAFC);

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel? user;
  const EditProfileScreen({super.key, this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _countryController;
  String? _homeType;
  String? _dietType;
  int? _householdSize;
  String? _preferredTransport;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  File? _newAvatarFile;           // locally selected, not yet uploaded
  String? _uploadedAvatarUrl;     // freshly uploaded URL (overrides Firestore)
  static const int _maxChars = 30;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.displayName ?? '');
    _countryController = TextEditingController(text: widget.user?.country ?? '');
    _homeType = widget.user?.homeType;
    _dietType = widget.user?.dietType;
    _householdSize = widget.user?.householdSize;
    _preferredTransport = widget.user?.preferredTransport;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // ── Pick + upload avatar ──────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _newAvatarFile = file;
      _isUploadingAvatar = true;
    });
    try {
      final url = await ref.read(profileControllerProvider.notifier).uploadAvatar(file);
      setState(() {
        _uploadedAvatarUrl = url;
        _isUploadingAvatar = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Profile photo updated! 📸', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ));
      }
    } catch (e) {
      setState(() {
        _newAvatarFile = null;
        _isUploadingAvatar = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  // ── Save name ─────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(profileControllerProvider.notifier).updateDisplayName(_nameController.text.trim());
      await ref.read(profileControllerProvider.notifier).updateAdditionalDetails({
        'country': _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        'home_type': _homeType,
        'diet_type': _dietType,
        'household_size': _householdSize,
        'preferred_transport': _preferredTransport,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Profile updated! ✓', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _nameController.text.length;
    final overLimit = charCount > _maxChars;

    // Resolve what to display in the avatar
    final existingPhotoUrl = widget.user?.photoUrl;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_isSaving || overLimit || _isUploadingAvatar) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('SAVE', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Tappable Avatar ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Avatar circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _kGreen, width: 3),
                          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: ClipOval(
                          child: _isUploadingAvatar
                              // Uploading spinner overlay
                              ? Container(
                                  color: Colors.black26,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                                )
                              : _newAvatarFile != null
                                  // Locally selected file preview
                                  ? Image.file(_newAvatarFile!, fit: BoxFit.cover)
                                  : (_uploadedAvatarUrl ?? existingPhotoUrl) != null
                                      // Network photo from Firebase
                                      ? Image.network(
                                          _uploadedAvatarUrl ?? existingPhotoUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) => progress == null
                                              ? child
                                              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        )
                                      // Fallback: gradient with initial
                                      : Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                                            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                        ),
                      ),

                      // Camera badge
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: _kGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 28),

              // ── Email (read-only) ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.email_outlined, color: Colors.grey.shade500, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(widget.user?.email ?? '—', style: GoogleFonts.inter(fontSize: 15, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text('Read-only', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Name field ───────────────────────────────────────────────
              _FieldCard(
                label: 'Display Name',
                hint: 'Enter your display name',
                icon: Icons.person_rounded,
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                maxChars: _maxChars,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name cannot be empty';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  if (v.trim().length > _maxChars) return 'Name cannot exceed $_maxChars characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              

              // ── Country field ───────────────────────────────────────────────
              _FieldCard(
                label: 'Country',
                hint: 'Where do you live?',
                icon: Icons.public_rounded,
                controller: _countryController,
                maxChars: 40,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // ── Eco Details Dropdowns ────────────────────────────────────────
              _DropdownCard(
                label: 'Diet Type',
                hint: 'Select diet',
                icon: Icons.restaurant_menu_rounded,
                value: _dietType,
                items: const {
                  'vegan': 'Vegan',
                  'vegetarian': 'Vegetarian',
                  'pescatarian': 'Pescatarian',
                  'mixed': 'Mixed',
                },
                onChanged: (val) => setState(() => _dietType = val),
              ),
              const SizedBox(height: 12),

              _DropdownCard(
                label: 'Home Type',
                hint: 'Select home type',
                icon: Icons.home_rounded,
                value: _homeType,
                items: const {
                  'apartment': 'Apartment',
                  'house': 'House',
                  'condo': 'Condo',
                  'other': 'Other',
                },
                onChanged: (val) => setState(() => _homeType = val),
              ),
              const SizedBox(height: 12),

              _DropdownCard(
                label: 'Household Size',
                hint: 'Number of people',
                icon: Icons.people_rounded,
                value: _householdSize == 6 ? '6+' : _householdSize?.toString(),
                items: const {
                  '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6+': '6+',
                },
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (val == '6+') _householdSize = 6;
                      else _householdSize = int.tryParse(val);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              _DropdownCard(
                label: 'Preferred Transport',
                hint: 'Main way to get around',
                icon: Icons.directions_car_rounded,
                value: _preferredTransport,
                items: const {
                  'car': 'Car',
                  'public_transport': 'Public Transport',
                  'bicycle': 'Bicycle',
                  'walking': 'Walking',
                  'electric_vehicle': 'Electric Vehicle',
                },
                onChanged: (val) => setState(() => _preferredTransport = val),
              ),
              const SizedBox(height: 12),

              
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int maxChars;

  const _FieldCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.maxChars,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final count = controller.text.length;
    final over = count > maxChars;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87))),
              Text('$count / $maxChars', style: GoogleFonts.inter(fontSize: 11, color: over ? Colors.red.shade400 : Colors.grey.shade400, fontWeight: over ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            validator: validator,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              errorStyle: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                )
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            dropdownColor: Colors.white,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          ),
        ],
      ),
    );
  }
}
