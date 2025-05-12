import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else {
    return 'http://10.0.2.2:8000';
  }
}

class ApiService {
  // Ürünleri çek
  static Future<List<Product>> fetchProducts() async {
    final url = Uri.parse('$getBaseUrl()/products');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['products'] as List;
      return data.map((e) => Product.fromJson(e)).toList();
    }
    throw Exception('Ürünler alınamadı (${res.statusCode})');
  }

  // Tarif öner
  static Future<String> suggestRecipe(List<String> names) async {
    final url = Uri.parse('$getBaseUrl()/recipes/suggest');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': names.join(',')}));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['suggestion'] ?? 'Cevap yok';
    }
    throw Exception('Tarif hatası (${res.statusCode})');
  }

  // Besin analizi
  static Future<Map<String, dynamic>> analyze(List<String> names) async {
    final url = Uri.parse('$getBaseUrl()/recipes/analyze');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': names.join(',')}));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['analysis'];
    }
    throw Exception('Analiz hatası (${res.statusCode})');
  }
}
