import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

String getRegisterUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000/auth/register';
  } else {
    return 'http://10.0.2.2:8000/auth/register';
  }
}

Future<void> registerUser() async {
  final url = Uri.parse(getRegisterUrl());
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "role": "user",
      "name": nameController.text.trim(),
      "surname": surnameController.text.trim(),
      "phone": phoneController.text.trim(),
    }),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kayıt başarılı!")),
    );
    Navigator.pop(context); // 🔁 Giriş ekranına dön
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Hata: ${data['detail']}")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E2E2E),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Kayıt Ol",
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(nameController, "İsim", isWeb: true),
                  const SizedBox(height: 16),
                  _buildTextField(surnameController, "Soyisim", isWeb: true),
                  const SizedBox(height: 16),
                  _buildTextField(emailController, "Email", isWeb: true),
                  const SizedBox(height: 16),
                  _buildTextField(phoneController, "Telefon Numarası", isWeb: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2552C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Kayıt Ol"),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Zaten hesabınız var mı?",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Giriş Yap",
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
          ),
        ),
      );
    }
    // Mobil için mevcut haliyle devam et
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Kayıt Ol",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(nameController, "İsim"),
              const SizedBox(height: 16),
              _buildTextField(surnameController, "Soyisim"),
              const SizedBox(height: 16),
              _buildTextField(emailController, "Email"),
              const SizedBox(height: 16),
              _buildTextField(passwordController, "Şifre", obscureText: true),
              const SizedBox(height: 16),
              _buildTextField(phoneController, "Telefon Numarası"),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2552C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Kayıt Ol",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Zaten hesabınız var mı?",
                style: TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Giriş Yap",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscureText = false, bool isWeb = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.black, fontSize: isWeb ? 22 : 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black45, fontSize: isWeb ? 22 : 16, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20, vertical: isWeb ? 22 : 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isWeb ? 40 : 30),
          borderSide: BorderSide.none,
        ),
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
