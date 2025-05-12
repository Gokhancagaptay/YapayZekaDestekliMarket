import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else {
    return 'http://10.0.2.2:8000';
  }
}

class AnalysisService {
  static Future<String> suggestRecipe(List<String> items) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/recipes/suggest'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'ingredients': items.join(', ')}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['suggestion'] ?? 'Öneri yapılamadı.';
      } else {
        throw Exception('Yemek önerisi alınamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Yemek önerisi alınamadı: $e');
    }
  }

  static Future<String> analyzeCartItems(List<String> items) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/recipes/analyze'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'ingredients': items}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? 'Analiz yapılamadı.';
      } else {
        throw Exception('Analiz yapılamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Analiz yapılamadı: $e');
    }
  }

  static Future<String> priceAnalysis(List<String> items) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/recipes/price'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'ingredients': items}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['price_analysis'] ?? 'Fiyat analizi yapılamadı.';
      } else {
        throw Exception('Fiyat analizi yapılamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Fiyat analizi yapılamadı: $e');
    }
  }

  static Future<String> customQuestion(List<String> items, String question) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/recipes/custom'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'ingredients': items, 'question': question}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Yanıt alınamadı.';
      } else {
        throw Exception('Yanıt alınamadı: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Yanıt alınamadı: $e');
    }
  }
} 