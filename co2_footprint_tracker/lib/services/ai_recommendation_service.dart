import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/activity.dart';
import '../models/ai_recommendation.dart';
import 'activity_service.dart';

class AiRecommendationService {
  final FirebaseFirestore _firestore;
  final ActivityService _activityService;

  AiRecommendationService(this._firestore, this._activityService);

  Future<AiRecommendation?> getOrGenerateRecommendation(String userId, String type, {bool forceRefresh = false}) async {
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiKey == null || geminiKey.isEmpty) {
      throw Exception('Gemini API key is missing');
    }

    final collection = _firestore.collection('ai_recommendations');

    if (!forceRefresh) {
      // 1. Check for cached valid recommendation
      final snapshot = await collection
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .where('expires_at', isGreaterThan: Timestamp.now())
          .orderBy('expires_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AiRecommendation.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
      }
      
      // If not forcing refresh and no cache exists, do NOT auto-generate to save Gemini calls.
      return null;
    }

    // 2. Aggregate Data
    final days = type == 'weekly' ? 7 : 1;
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));

    final allActivities = await _activityService.getUserActivities(userId);
    final recentActivities = allActivities.where((a) => a.createdAt.toDate().isAfter(cutoff)).toList();

    if (recentActivities.isEmpty) {
      return null; // Not enough data to generate meaningful advice
    }

    double totalCo2 = 0;
    double transportCo2 = 0;
    double foodCo2 = 0;
    double energyCo2 = 0;
    
    // Track habits for top emission sources
    Map<String, double> habitCounts = {};

    for (var act in recentActivities) {
      totalCo2 += act.co2Kg;
      
      String habitKey = '';
      if (act is TransportActivity) {
        transportCo2 += act.co2Kg;
        habitKey = 'Transport: ${act.transportMode}';
      } else if (act is FoodActivity) {
        foodCo2 += act.co2Kg;
        habitKey = 'Food: ${act.foodCategory}';
      } else if (act is EnergyActivity) {
        energyCo2 += act.co2Kg;
        habitKey = 'Energy: ${act.energyType}';
      }
      habitCounts[habitKey] = (habitCounts[habitKey] ?? 0) + act.co2Kg;
    }

    // Sort habits
    final sortedHabits = habitCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topHabits = sortedHabits.take(3).map((e) => e.key).join(", ");

    // 3. Call Gemini
    final prompt = '''
You are a sustainability expert for a mobile app.
User carbon footprint summary (Last ${days} days):
Total CO2: ${totalCo2.toStringAsFixed(1)} kg

Breakdown:
- Transport: ${transportCo2.toStringAsFixed(1)} kg
- Food: ${foodCo2.toStringAsFixed(1)} kg
- Energy: ${energyCo2.toStringAsFixed(1)} kg

Top emitting habits/items: $topHabits

Return EXACTLY in this JSON format:
{
  "summary": "1 short sentence identifying top emission sources",
  "actions": ["1st personalized action", "2nd personalized action", "3rd personalized action"],
  "goal": "1 realistic ${type} goal"
}
    '''.trim();

    final geminiUri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiKey');
    
    final response = await http.post(
      geminiUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts":[{"text": prompt}]}],
        "generationConfig": {
          "responseMimeType": "application/json"
        }
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final geminiData = jsonDecode(response.body);
      final recommendationText = geminiData['candidates'][0]['content']['parts'][0]['text'];

      // 4. Save to Firestore
      final expiresAt = now.add(Duration(days: days)); // Expires in exactly 1 cycle (24h or 7d)

      // Find if we have an existing one to OVERWRITE to keep the db clean
      String docId = collection.doc().id;
      final existingDoc = await collection
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .get();
          
      if (existingDoc.docs.isNotEmpty) {
        docId = existingDoc.docs.first.id;
      }

      final recommendation = AiRecommendation(
        id: docId,
        userId: userId,
        type: type,
        generatedAt: Timestamp.fromDate(now),
        totalCo2: totalCo2,
        recommendation: recommendationText,
        expiresAt: Timestamp.fromDate(expiresAt),
      );

      await collection.doc(docId).set(recommendation.toMap());

      return recommendation;
    } else {
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
