import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboardService {
  // Backend URL'sini platforma göre ayarla
  final String _baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final url = Uri.parse('$_baseUrl/api/admin/dashboard/stats');
    print('AdminDashboardService: Dashboard istatistikleri isteniyor: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('AdminDashboardService: Dashboard istatistikleri başarıyla alındı: $data');
        return {
          'totalCompletedRevenue': data['totalCompletedRevenue'] ?? 0.0,
          'activeOrdersCount': data['activeOrdersCount'] ?? 0,
          'totalUsers': data['totalUsers'] ?? 0,
        };
      } else {
        print('AdminDashboardService: Dashboard istatistikleri alınamadı - Hata kodu: ${response.statusCode}');
        print('AdminDashboardService: Hata mesajı: ${response.body}');
        throw Exception('Dashboard istatistikleri sunucudan alınamadı (Hata: ${response.statusCode})');
      }
    } catch (e) {
      print('AdminDashboardService: Dashboard istatistikleri alınırken bir ağ veya başka bir hata oluştu: $e');
      throw Exception('Dashboard istatistikleri alınırken bir hata oluştu: $e');
    }
  }
} 