import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_page.dart' show GirisEkrani;
import 'screens/product_list.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart'; // giriş ekranı dosyanın adını buna göre ayarlamayı unutma

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Market',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF2E2E2E),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      // ilk yönlendirme ekranı:
      home: isLoggedIn ? const ProductListPage() : const GirisEkrani(),

      // sayfa rotaları:
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const GirisEkrani(), // Giriş ekranı rotası
        '/products': (context) => const ProductListPage(), // Ürün sayfası
      },
    );
  }
}
