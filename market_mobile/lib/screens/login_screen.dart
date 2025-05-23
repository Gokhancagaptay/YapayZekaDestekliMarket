import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../main.dart'; // responsiveWrapper fonksiyonunu kullanmak için
  // TEST: BU DOSYA GÜNCELLENDİ
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  String getApiUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000/api/auth/login';
    } else {
      return 'http://10.0.2.2:8000/api/auth/login';
    }
  }

  Future<void> loginUser() async {
    debugPrint('Sign In butonuna basıldı!');
    setState(() { isLoading = true; });
    final url = Uri.parse(getApiUrl());
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": emailController.text,
        "password": passwordController.text,
      }),
    );
    setState(() { isLoading = false; });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data["idToken"];
      final uid = data["uid"];
      // Token'ı shared_preferences ile sakla (web ve mobilde çalışır)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('idToken', token);
      await prefs.setString('token', token);
      await prefs.setString('uid', uid);
      await prefs.setString('email', emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş başarılı!")),
      );
      // Ana sayfaya yönlendir
      Navigator.pushReplacementNamed(context, "/products");
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: "+(data['detail']?.toString() ?? 'Bilinmeyen hata'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: Center(
        child: isWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Find the Best\nHealth for You",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 56),
                      _buildTextField(emailController, "Email", icon: Icons.email, isWeb: true),
                      const SizedBox(height: 24),
                      _buildTextField(passwordController, "Password", icon: Icons.lock, obscureText: true, isWeb: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2552C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Sign In"),
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        "Hesabınız yok mu?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pushNamed(context, "/register"),
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Find the Best\nHealth for You",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildTextField(emailController, "Email", icon: Icons.email, isWeb: false),
                      const SizedBox(height: 16),
                      _buildTextField(passwordController, "Password", icon: Icons.lock, obscureText: true, isWeb: false),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2552C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Hesabınız yok mu?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pushNamed(context, "/register"),
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool obscureText = false, IconData? icon, bool isWeb = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          color: isWeb ? Colors.black87 : Colors.black,
          fontSize: isWeb ? 22 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isWeb ? Colors.black38 : Colors.black45,
            fontSize: isWeb ? 22 : 16,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: icon != null
              ? Icon(icon, color: isWeb ? Colors.black87 : Colors.black45, size: isWeb ? 30 : 22)
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20, vertical: isWeb ? 26 : 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isWeb ? 40 : 16),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) {
          if (!isLoading) loginUser();
        },
      ),
    );
  }
}
