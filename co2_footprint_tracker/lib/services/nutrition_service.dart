import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/nutrition_model.dart';

class NutritionService {
  Future<NutritionModel> getNutritionAndCo2(String foodName) async {
    final usdaKey = dotenv.env['USDA_API_KEY'];
    final geminiKey = dotenv.env['GEMINI_API_KEY'];

    if (geminiKey == null || geminiKey.isEmpty) {
      throw Exception('Gemini API key is missing in .env');
    }

    Map<String, double>? nutritionData;
    String source = 'Gemini AI Estimated';

    // 1. Try USDA API
    if (usdaKey != null && usdaKey.isNotEmpty) {
      try {
        final usdaUri = Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$usdaKey&query=${Uri.encodeComponent(foodName)}&pageSize=1');
        final response = await http.get(usdaUri).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['foods'] != null && data['foods'].isNotEmpty) {
            final foodInfo = data['foods'][0];
            final nutrients = foodInfo['foodNutrients'] as List;
            
            double getNutrient(int nutrientId) {
              final n = nutrients.firstWhere((element) => element['nutrientId'] == nutrientId, orElse: () => null);
              return n != null ? (n['value'] as num).toDouble() : 0.0;
            }

            // Energy (1008), Protein (1003), Total Lipid/Fat (1004), Carbohydrate (1005)
            nutritionData = {
              'calories': getNutrient(1008),
              'protein': getNutrient(1003),
              'fat': getNutrient(1004),
              'carbs': getNutrient(1005),
            };
            source = 'USDA FoodData Central';
          }
        }
      } catch (e) {
        // USDA failed or timeout, we will fallback to Gemini
        print('USDA API error: $e');
      }
    }

    // 2. Query Gemini for CO2 and fallback nutrition
    final prompt = _buildGeminiPrompt(foodName, nutritionData == null);
    
    final geminiUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiKey');
    
    try {
      final geminiResponse = await http.post(
        geminiUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts":[{"text": prompt}]}],
          "generationConfig": {
            "responseMimeType": "application/json",
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (geminiResponse.statusCode == 200) {
        final geminiData = jsonDecode(geminiResponse.body);
        final textResponse = geminiData['candidates'][0]['content']['parts'][0]['text'];
        final parsedJson = jsonDecode(textResponse);

        return NutritionModel(
          calories: nutritionData?['calories'] ?? (parsedJson['calories'] as num?)?.toDouble() ?? 0.0,
          protein: nutritionData?['protein'] ?? (parsedJson['protein'] as num?)?.toDouble() ?? 0.0,
          fat: nutritionData?['fat'] ?? (parsedJson['fat'] as num?)?.toDouble() ?? 0.0,
          carbs: nutritionData?['carbs'] ?? (parsedJson['carbs'] as num?)?.toDouble() ?? 0.0,
          source: source,
          co2EstimateKg: (parsedJson['co2_kg'] as num?)?.toDouble() ?? 0.0,
          matchedCategory: parsedJson['category'] as String? ?? 'vegetarian',
        );
      } else {
        throw Exception('Gemini API error ${geminiResponse.statusCode}: ${geminiResponse.body}');
      }
    } catch (e) {
      throw Exception('Failed to get insights from Gemini: $e');
    }
  }

  String _buildGeminiPrompt(String foodName, bool needsNutrition) {
    String nutritionInstruction = needsNutrition 
      ? '"calories": <number in kcal>, "protein": <number in grams>, "fat": <number in grams>, "carbs": <number in grams>,'
      : '';
    
    return '''
Analyze the food item: "$foodName".
Provide the data in a valid JSON format EXACTLY like this:
{
  $nutritionInstruction
  "co2_kg": <estimated CO2 footprint in kg per serving as a number>,
  "category": "<Must be exactly one of: meat_beef, meat_pork, meat_chicken, fish, dairy, vegetarian, vegan>"
}
    '''.trim();
  }
}
