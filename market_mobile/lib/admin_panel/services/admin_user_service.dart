import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AdminUserService {
  // Backend API URL'nizi buraya girin
  // localhost için mobil emülatörde genellikle 10.0.2.2 kullanılır
  // Web için localhost:8000 veya kendi domaininiz
  final String _baseUrl = kIsWeb ? 'http://localhost:8000/api/admin' : 'http://10.0.2.2:8000/api/admin';

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    print('AdminUserService: Kullanicilar API\'den yukleniyor...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> usersData = responseData['users'];
        final List<Map<String, dynamic>> usersList = usersData.map((userData) {
          // Backend'den gelen timestamp'leri DateTime objesine çevirelim
          DateTime? creationTime;
          if (userData['creationTimestamp'] != null) {
            creationTime = DateTime.fromMillisecondsSinceEpoch(userData['creationTimestamp']);
          }
          DateTime? lastSignInTime;
          if (userData['lastSignInTimestamp'] != null) {
            lastSignInTime = DateTime.fromMillisecondsSinceEpoch(userData['lastSignInTimestamp']);
          }

          return {
            'uid': userData['uid'],
            'email': userData['email'] ?? 'Email Yok',
            'displayName': userData['displayName'] ?? (userData['name'] != null && userData['name'].isNotEmpty ? '${userData['name']} ${userData['surname'] ?? ''}'.trim() : 'İsimsiz Kullanıcı'),
            'name': userData['name'] ?? '',
            'surname': userData['surname'] ?? '',
            'phone': userData['phone'] ?? '',
            'photoURL': userData['photoURL'],
            'role': userData['role'] ?? 'user',
            'disabled': userData['disabled'] ?? false,
            'status': (userData['disabled'] ?? false) ? 'Devre Dışı' : 'Aktif',
            'creationTimestamp': creationTime?.toIso8601String(),
            'lastSignInTimestamp': lastSignInTime?.toIso8601String(),
          };
        }).toList();
        print('AdminUserService: ${usersList.length} kullanici API\'den yuklendi.');
        return usersList;
      } else {
        print('AdminUserService: Kullanici yukleme hatasi - Durum Kodu: ${response.statusCode}');
        print('AdminUserService: Hata Mesaji: ${response.body}');
        throw Exception('Kullanicilar API\'den yuklenemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminUserService: Kullanici yukleme API cagrisi hatasi: $e');
      throw Exception('Kullanici yukleme sirasinda bir hata olustu: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    print('AdminUserService: Kullanici ($userId) rolu guncelleniyor: $newRole');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/role'),
        headers: await _getHeaders(),
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        print('AdminUserService: Kullanici ($userId) rolu basariyla guncellendi.');
      } else {
        print('AdminUserService: Kullanici rolu guncelleme hatasi - Durum Kodu: ${response.statusCode}');
        print('AdminUserService: Hata Mesaji: ${response.body}');
        throw Exception('Kullanici rolu guncellenemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminUserService: Kullanici rolu guncelleme API cagrisi hatasi: $e');
      throw Exception('Kullanici rolu guncellenirken bir hata olustu: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    print('AdminUserService: Kullanici ($userId) siliniyor...');
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        print('AdminUserService: Kullanici ($userId) basariyla silindi.');
      } else {
        print('AdminUserService: Kullanici silme hatasi - Durum Kodu: ${response.statusCode}');
        print('AdminUserService: Hata Mesaji: ${response.body}');
        throw Exception('Kullanici silinemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminUserService: Kullanici silme API cagrisi hatasi: $e');
      throw Exception('Kullanici silinirken bir hata olustu: $e');
    }
  }

  Future<void> setUserDisabledStatus(String userId, bool isDisabled) async {
    final action = isDisabled ? 'disable' : 'enable';
    print('AdminUserService: Kullanici ($userId) durumu guncelleniyor: ${isDisabled ? "Devre Disi" : "Aktif"}');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/$action'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        print('AdminUserService: Kullanici ($userId) durumu basariyla guncellendi.');
      } else {
        print('AdminUserService: Kullanici durumu guncelleme hatasi - Durum: ${response.statusCode}');
        print('AdminUserService: Hata: ${response.body}');
        throw Exception('Kullanici durumu guncellenemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminUserService: API cagrisi sirasinda hata: $e');
      throw Exception('Kullanici durumu guncellenirken bir hata olustu: $e');
    }
  }

  // Admin panelinde doğrudan kullanıcı ekleme işlevi genellikle olmaz.
  // Kullanıcılar genellikle kayıt ekranından kendileri kayıt olur.
  // Eğer adminin kullanıcı oluşturma yetkisi olacaksa, bunun için de bir backend endpoint'i gerekir.
  // Şimdilik bu fonksiyonu kaldırıyorum veya yorum satırına alıyorum.
  /*
  Future<void> addUser(Map<String, dynamic> user) async {
    // Backend'de /api/admin/users POST endpoint'i oluşturulursa burası doldurulabilir.
    print('AdminUserService: Web icin demo kullanici ekleme simulasyonu.');
  }
  */

  // Web için demo kullanıcıları döndüren yardımcı fonksiyon (artık kullanılmıyor, API'den çekilecek)
  // List<Map<String, dynamic>> _getDemoUsers() { ... }
} 