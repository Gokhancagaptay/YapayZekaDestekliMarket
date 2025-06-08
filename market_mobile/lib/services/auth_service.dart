import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'token'; // SharedPreferences'ta token'ın saklandığı anahtar

  // Kayıtlı token'ı getirir
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Kayıtlı token olup olmadığını kontrol eder
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Yetkilendirme başlıklarını (Authorization header dahil) oluşturur
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Token'ı kaydeder (Login sonrası çağrılır)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('AuthService: Token kaydedildi.');
  }

  // Token'ı siler (Logout sonrası çağrılır)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('idToken');
    await prefs.remove('uid');
    await prefs.remove('email');
    await prefs.setBool('isLoggedIn', false);
    print('AuthService: Tüm yetkilendirme verileri temizlendi.');
  }
} 