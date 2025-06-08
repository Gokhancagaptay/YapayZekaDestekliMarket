import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:market_mobile/admin_panel/admin_main.dart';
import 'package:market_mobile/screens/login_screen.dart';
import 'package:market_mobile/screens/product_list.dart'; // Admin olmayanlar için ana sayfa

class AdminRouteGuard extends StatefulWidget {
  const AdminRouteGuard({super.key});

  @override
  State<AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  Future<Map<String, dynamic>> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'userRole': prefs.getString('userRole'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // Hata durumunda veya veri yoksa login ekranına yönlendir
          // veya daha spesifik bir hata ekranı gösterilebilir.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return const Scaffold(body: Center(child: Text("Yönlendiriliyor...")));
        }

        final bool isLoggedIn = snapshot.data!['isLoggedIn'];
        final String? userRole = snapshot.data!['userRole'];

        if (isLoggedIn && userRole == 'admin') {
          // Doğrudan AdminMain'i döndürmek yerine, Navigator ile yönlendirme daha temiz olabilir
          // Ancak bu durumda doğrudan widget'ı göstermek de bir seçenek.
          // Eğer AdminMain kendi içinde state yönetimi yapıyorsa bu sorun olmaz.
           return const AdminMain();
        } else if (isLoggedIn) {
          // Giriş yapmış ama admin değilse ana sayfaya (ürün listesi) yönlendir
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProductListPage()),
            );
          });
          return const Scaffold(body: Center(child: Text("Yetkiniz yok, yönlendiriliyor...")));
        } else {
          // Giriş yapmamışsa login sayfasına yönlendir
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return const Scaffold(body: Center(child: Text("Giriş yapmanız gerekli, yönlendiriliyor...")));
        }
      },
    );
  }
} 