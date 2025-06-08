import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminOrderService {
  final String _baseUrl = kIsWeb ? 'http://localhost:8000/api/admin/orders' : 'http://10.0.2.2:8000/api/admin/orders';

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    if (token == null) {
      // Token yoksa yetkilendirme gerektiren istekler başarısız olabilir.
      // Bu durumu ele almak gerekebilir (örn: login ekranına yönlendirme).
      print('AdminOrderService Uyarı: Yetkilendirme tokenı bulunamadı.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> fetchOrders({String? statusFilter}) async {
    print('AdminOrderService: Siparisler API üzerinden yükleniyor (Filtre: ${statusFilter ?? "yok"})...');
    try {
      Map<String, String> queryParams = {};
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['status'] = statusFilter;
      }
      
      Uri uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        // Gelen veri zaten List<AdminOrderResponse> modeline uygun olmalı.
        // Her bir elemanın Map<String, dynamic> olduğundan emin olalım.
        final List<Map<String, dynamic>> ordersList = responseData.map((order) {
          if (order is Map<String, dynamic>) {
            // Backend'den gelen timestamp'i DateTime objesine veya formatlı string'e çevirebiliriz
            // Şimdilik olduğu gibi bırakıyoruz, UI tarafında formatlanabilir.
            // Örnek: order['timestamp'] = DateTime.fromMillisecondsSinceEpoch((order['timestamp'] as num).toInt());
            return order;
          }
          return <String, dynamic>{}; // Hatalı veri tipi için boş map
        }).where((order) => order.isNotEmpty).toList(); // Boş map'leri filtrele

        print('AdminOrderService: ${ordersList.length} sipariş API üzerinden yüklendi.');
        return ordersList;
      } else {
        print('AdminOrderService: Siparis yükleme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        throw Exception('Siparisler API üzerinden yüklenemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminOrderService: Siparis yükleme API çağrısı hatası: $e');
      throw Exception('Siparis yükleme sırasında bir hata oluştu: $e');
    }
  }

  Future<bool> updateOrderStatus(String customerUserId, String firebaseOrderId, String newStatus) async {
    print('AdminOrderService: Siparis durumu güncelleniyor - MusteriID: $customerUserId, SiparisID: $firebaseOrderId, Yeni Durum: $newStatus');
    try {
      final String url = kIsWeb 
          ? 'http://localhost:8000/api/admin/orders/$customerUserId/$firebaseOrderId/status' 
          : 'http://10.0.2.2:8000/api/admin/orders/$customerUserId/$firebaseOrderId/status';
      
      final response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        print('AdminOrderService: Siparis durumu başarıyla güncellendi. Yanıt: $responseBody');
        return true;
      } else {
        print('AdminOrderService: Siparis durumu güncelleme hatası - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Siparis durumu güncellenemedi: ${errorBody["detail"] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('AdminOrderService: Siparis durumu güncelleme API çağrısı hatası: $e');
      throw Exception('Siparis durumu güncellenirken bir hata oluştu: $e');
    }
  }
} 