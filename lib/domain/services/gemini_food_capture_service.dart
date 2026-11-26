import 'dart:convert';

import 'package:http/http.dart' as http;

class AiParsedFoodItem {
  const AiParsedFoodItem({
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
  });

  final String name;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  static double _safeNonNeg(dynamic v, [double fallback = 0.0]) {
    if (v is num) {
      final d = v.toDouble();
      if (d.isFinite && d >= 0.0) return d;
    }
    return fallback;
  }

  factory AiParsedFoodItem.fromJson(Map<String, dynamic> json) {
    return AiParsedFoodItem(
      name: (json['name'] as String?) ?? 'Food Item',
      grams: _safeNonNeg(json['grams'], 100.0),
      calories: _safeNonNeg(json['calories']),
      protein: _safeNonNeg(json['protein']),
      carbs: _safeNonNeg(json['carbs']),
      fat: _safeNonNeg(json['fat']),
      fiber: _safeNonNeg(json['fiber']),
    );
  }
}

/// Opt-in Gemini API client for natural-language Food Describe logging.
/// Sique's core logging remains 100% offline; this service only runs when
/// the user explicitly configures a Gemini API key via secure storage.
class GeminiFoodCaptureService {
  const GeminiFoodCaptureService._();

  static const String apiKeySettingKey = 'gemini_api_key';

  static Future<List<AiParsedFoodItem>> parseNaturalLanguageMeal({
    required String description,
    required String apiKey,
    http.Client? client,
  }) async {
    final trimmedKey = apiKey.trim();
    final trimmedDesc = description.trim();
    if (trimmedKey.isEmpty ||
        trimmedDesc.isEmpty ||
        trimmedDesc.length > 1000) {
      return const [];
    }

    final httpClient = client ?? http.Client();
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/gemini-2.0-flash:generateContent',
    );
    final prompt =
        'Parse this meal description into a JSON array of objects with keys: '
        'name (string), grams (number), calories (number), protein (number), '
        'carbs (number), fat (number), fiber (number). Return ONLY valid JSON.\n'
        'Meal: $trimmedDesc';

    try {
      final resp = await httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': trimmedKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode < 200 ||
          resp.statusCode >= 300 ||
          resp.bodyBytes.length > 512 * 1024) {
        return const [];
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return const [];
      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return const [];
      final text = parts.first['text'] as String?;
      if (text == null || text.isEmpty) return const [];
      final parsed = jsonDecode(text);
      if (parsed is! List) return const [];
      return parsed
          .whereType<Map<String, dynamic>>()
          .map(AiParsedFoodItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
