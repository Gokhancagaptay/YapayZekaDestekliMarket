import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart' show GirisEkrani;
import 'screens/product_list.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart' show LoginScreen;
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';

// Responsive wrapper fonksiyonu
typedef ResponsiveChild = Widget Function(BuildContext context);

Widget responsiveWrapper({required BuildContext context, required Widget child}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (kIsWeb && constraints.maxWidth > 600) {
        return Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        );
      } else {
        return child;
      }
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCqMqAcS8i-xoGD2_KsJeut0qMLfYngrSA",
        authDomain: "onlinemarket-12345.firebaseapp.com",
        projectId: "onlinemarket-12345",
        storageBucket: "onlinemarket-12345.appspot.com",
        messagingSenderId: "123456789",
        appId: "1:123456789:web:abcdef123456789",
        databaseURL: "https://onlinemarket-12345-default-rtdb.firebaseio.com",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
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
    final ThemeData mobileTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF2E2E2E),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
    final ThemeData webTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.light().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
    );

    if (isLoading) {
      return MaterialApp(
        theme: kIsWeb ? webTheme : mobileTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Online Market',
        theme: kIsWeb ? webTheme : mobileTheme,
        // ilk yönlendirme ekranı:
        home: isLoggedIn ? const ProductListPage() : const LoginScreen(),

        // sayfa rotaları:
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(), // Giriş ekranı rotası
          '/products': (context) => const ProductListPage(), // Ürün sayfası
        },
      ),
    );
  }
}
