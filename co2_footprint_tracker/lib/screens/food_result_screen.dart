import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/food_ai_provider.dart';
import '../../widgets/nutrition_card.dart';

class FoodResultScreen extends ConsumerWidget {
  const FoodResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodAIProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('AI Analysis', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!state.isLoading && state.error == null)
             IconButton(icon: const Icon(Icons.refresh), onPressed: () {
               if (state.image != null) ref.read(foodAIProvider.notifier).analyzeFood(state.image!);
             }),
        ],
      ),
      body: _buildBody(context, state),
      bottomNavigationBar: (!state.isLoading && state.error == null && state.nutrition != null)
          ? _buildBottomBar(context, state)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, FoodAIState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.image != null)
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: FileImage(state.image!), fit: BoxFit.cover)),
                margin: const EdgeInsets.only(bottom: 30),
              ),
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 20),
            Text('Analyzing your food...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              Text('Analysis Failed', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(state.error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey.shade700)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    if (state.prediction == null || state.nutrition == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(state.image!, height: 250, fit: BoxFit.cover, width: double.infinity),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _formatPrediction(state.prediction!.prediction),
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _getConfidenceColor(state.prediction!.confidence).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${state.prediction!.confidence.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _getConfidenceColor(state.prediction!.confidence)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.prediction!.confidence < 60)
             Text('Low confidence prediction. Result may be inaccurate.', style: GoogleFonts.inter(color: Colors.orange, fontSize: 12)),
          
          const SizedBox(height: 32),
          NutritionCard(nutrition: state.nutrition!),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatPrediction(String pred) {
    return pred.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  Widget _buildBottomBar(BuildContext context, FoodAIState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            // Give data back to FoodCaptureScreen, which forwards it to AddActivityScreen
            Navigator.pop(context, state.nutrition); 
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text('Confirm & Log Food', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
