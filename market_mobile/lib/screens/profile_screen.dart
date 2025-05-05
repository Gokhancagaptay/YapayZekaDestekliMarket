import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:market_mobile/screens/home_page.dart'; // giriş ekranına yönlendirme için

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GirisEkrani()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile.jpg'), // dilersen network image yapabilirsin
              ),
              const SizedBox(height: 16),
              const Text(
                "Mehmet Yılmaz",
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "+90 505 123 45 67",
                style: TextStyle(color: Colors.white70),
              ),
              const Text(
                "mehmet@example.com",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              _buildMenuItem(Icons.person, "Hesabım"),
              _buildMenuItem(Icons.shopping_bag, "Siparişlerim"),
              _buildMenuItem(Icons.favorite, "Favoriler"),
              _buildMenuItem(Icons.qr_code, "Stoğum"),
              _buildMenuItem(Icons.location_on, "Adreslerim"),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Çıkış Yap",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {}, // İleride yönlendirme yapılabilir
      ),
    );
  }
}
