import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/food_ai_provider.dart';
import 'food_result_screen.dart';

class FoodCaptureScreen extends ConsumerStatefulWidget {
  const FoodCaptureScreen({super.key});

  @override
  ConsumerState<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

class _FoodCaptureScreenState extends ConsumerState<FoodCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      if (!mounted) return;
      
      // Navigate to Result screen immediately, and let it handle the loading state
      ref.read(foodAIProvider.notifier).analyzeFood(File(image.path));
      
      // Get the nutrition back when popped
      final nutritionResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FoodResultScreen()),
      );

      // If finished logging/confirming, pass back to AddActivityScreen
      if (nutritionResult != null && mounted) {
        Navigator.pop(context, nutritionResult);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Scan Food', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.document_scanner_rounded, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Identify food & get nutrition\ninsights with AI',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(
              'Take a photo or upload from gallery to start analyzing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: Text('Take Photo', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: Icon(Icons.photo_library, color: Colors.orange.shade600),
              label: Text('Choose from Gallery', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.shade600, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
