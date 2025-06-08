import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:market_mobile/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'address_list_screen.dart';
import 'stock_screen.dart';
import 'account_screen.dart';
import 'order_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool inPanel;
  const ProfileScreen({super.key, this.inPanel = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      print("Token bulunamadı!");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oturum bilgisi bulunamadı")),
      );
      return;
    }

    print("Token alındı: ${token.substring(0, 20)}...");  // Token'ın ilk 20 karakterini göster

    try {
      final response = await http.get(
        Uri.parse(getProfileUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Sunucu yanıtı: ${response.statusCode}");
      print("Sunucu yanıt içeriği: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${response.body}")),
        );
      }
    } catch (e) {
      print("Hata oluştu: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı hatası: $e")),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final loader = const Center(child: CircularProgressIndicator());
      if (widget.inPanel) return loader;
      return const Scaffold(
        backgroundColor: Color(0xFF2E2E2E),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final email = userData?['email'] ?? '';
    final phone = userData?['phone'] ?? '';
    final name = userData?['name'] ?? '';
    final surname = userData?['surname'] ?? '';

    final menuItems = [
      {'icon': Icons.person, 'title': 'Hesabım'},
      {'icon': Icons.shopping_bag, 'title': 'Siparişlerim'},
      {'icon': Icons.inventory, 'title': 'Stoğum'},
      {'icon': Icons.location_on, 'title': 'Adreslerim'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                      image: userData != null && userData!['profile_image'] != null
                          ? DecorationImage(
                              image: NetworkImage(userData!['profile_image']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: userData == null || userData!['profile_image'] == null
                        ? const Icon(Icons.person, color: Colors.white, size: 64)
                        : null,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "$name $surname",
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Column(
                    children: menuItems.map((item) => _buildModernMenuItem(item['icon'] as IconData, item['title'] as String)).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      child: const Text(
                        "Çıkış Yap",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF353535),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          if (title == 'Hesabım') {
            if (kIsWeb) {
              // Web: yan panelde aç
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Kapat",
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: AccountScreen(
                        inPanel: true, 
                        userData: userData,
                        refreshParent: () => fetchUserData(),
                      ),
                    ),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
                    child: child,
                  );
                },
              );
            } else {
              // Mobil: tam ekran aç
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountScreen(
                    userData: userData,
                    refreshParent: () => fetchUserData(),
                  )
                ),
              );
            }
          } else if (title == 'Siparişlerim') {
            if (kIsWeb) {
              // Web: yan panelde aç
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Kapat",
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: OrderScreen(),
                    ),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
                    child: child,
                  );
                },
              );
            } else {
              // Mobil: tam ekran aç
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderScreen()),
              );
            }
          } else if (title == 'Adreslerim') {
            if (kIsWeb) {
              // Web: yan panelde aç
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Kapat",
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: AddressListScreen(inPanel: true),
                    ),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
                    child: child,
                  );
                },
              );
            } else {
              // Mobil: tam ekran aç
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressListScreen()),
              );
            }
          } else if (title == 'Stoğum') {
            if (kIsWeb) {
              // Web: yan panelde aç
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Kapat",
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: StockScreen(inPanel: true),
                    ),
                  );
                },
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
                    child: child,
                  );
                },
              );
            } else {
              // Mobil: tam ekran aç
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StockScreen()),
              );
            }
          }
        },
      ),
    );
  }

  String getProfileUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000/api/auth/me';
    } else {
      return 'http://10.0.2.2:8000/api/auth/me';
    }
  }
}
