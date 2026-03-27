import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/nutrition_model.dart';

class NutritionCard extends StatelessWidget {
  final NutritionModel nutrition;

  const NutritionCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.green.shade100, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nutrition Insights', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(nutrition.source, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Nutrient(label: 'Calories', value: '${nutrition.calories.toStringAsFixed(0)} kcal', icon: '🔥', color: Colors.orange),
              _Nutrient(label: 'Protein', value: '${nutrition.protein.toStringAsFixed(1)} g', icon: '🥩', color: Colors.redAccent),
              _Nutrient(label: 'Fat', value: '${nutrition.fat.toStringAsFixed(1)} g', icon: '🧈', color: Colors.amber),
              _Nutrient(label: 'Carbs', value: '${nutrition.carbs.toStringAsFixed(1)} g', icon: '🍞', color: Colors.brown),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text('Estimated CO₂ Footprint', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
                Text('${nutrition.co2EstimateKg.toStringAsFixed(2)} kg', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Nutrient extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _Nutrient({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
