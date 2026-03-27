import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/food_prediction_model.dart';

class FoodAIService {
  Future<FoodPredictionModel> predictFood(File imageFile) async {
    final baseUrl = dotenv.env['FASTAPI_URL'] ?? 'http://192.168.1.13:8000';
    final uri = Uri.parse('$baseUrl/predict');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FoodPredictionModel.fromJson(data);
      } else {
        throw Exception('Failed to predict food: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error or timeout: $e');
    }
  }
}
