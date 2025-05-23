import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else {
    return 'http://10.0.2.2:8000';
  }
}

class StockService {
  static Future<List<Map<String, dynamic>>> fetchUserStock() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final token = prefs.getString('token');
    if (uid == null || token == null) return [];
    final url = '${getBaseUrl()}/api/auth/users/$uid/stock';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> addOrUpdateStock(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final token = prefs.getString('token');
    if (uid == null || token == null) return;
    final url = '${getBaseUrl()}/api/auth/users/$uid/stock';
    
    // Stok öğesi için gerekli alanları hazırla
    final stockItem = {
      'product_id': item['id'],
      'name': item['name'],
      'image_url': item['image_url'],
      'quantity': item['qty'],
      'unit': item['unit'],
      'category': (item['category'] ?? 'belirsiz'), // Kategori mutlaka eklenecek
      'price': item['price'],
      'stock': item['stock'],
    };

    await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(stockItem),
    );
  }

  static Future<void> deleteStockItem(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final token = prefs.getString('token');
    if (uid == null || token == null) return;
    final url = '${getBaseUrl()}/api/auth/users/$uid/stock/$productId';
    await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
} 