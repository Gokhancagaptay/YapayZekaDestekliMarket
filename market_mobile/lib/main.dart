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
import 'package:market_mobile/admin_panel/admin_main.dart';
import 'package:market_mobile/admin_panel/admin_route_guard.dart';
import 'package:intl/date_symbol_data_local.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  // Firebase yapılandırma bilgilerini buraya girin
  const firebaseApiKey = "YOUR_FIREBASE_API_KEY"; 
  const firebaseAuthDomain = "YOUR_FIREBASE_AUTH_DOMAIN";
  const firebaseProjectId = "YOUR_FIREBASE_PROJECT_ID"; 
  const firebaseStorageBucket = "YOUR_FIREBASE_STORAGE_BUCKET";
  const firebaseMessagingSenderId = "YOUR_FIREBASE_MESSAGING_SENDER_ID";
  const firebaseAppIdWeb = "YOUR_FIREBASE_APP_ID_WEB"; // Web için
  const firebaseDatabaseURL = "YOUR_FIREBASE_DATABASE_URL";

  if (Firebase.apps.isEmpty) {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: firebaseApiKey,
          authDomain: firebaseAuthDomain,
          projectId: firebaseProjectId,
          storageBucket: firebaseStorageBucket,
          messagingSenderId: firebaseMessagingSenderId,
          appId: firebaseAppIdWeb, // Web App ID
          databaseURL: firebaseDatabaseURL, 
        ),
      );
    } else {
      // Mobil platformlar için parametresiz başlatma
      // Bu, projenizde google-services.json (Android) ve GoogleService-Info.plist (iOS)
      // dosyalarının doğru şekilde yapılandırıldığını varsayar.
      await Firebase.initializeApp(); 
    }
  } else {
    print("Firebase zaten başlatılmış.");
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
  String? userRole; // Kullanıcı rolünü tutmak için eklendi

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userRole = prefs.getString('userRole'); // Kullanıcı rolünü SharedPreferences'tan oku
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData mobileTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF2E2E2E),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white, // Varsayılan gövde metni rengi
        displayColor: Colors.white, // Varsayılan başlık metni rengi
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Mobil için buton arka planı
          foregroundColor: Colors.black, // Mobil için buton metin/ikon rengi
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.grey[850], // Mobil için kartların arka plan rengi
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[700]), // Mobil DataTable başlık satırı arka planı
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Mobil DataTable başlık metin stili
        dataRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey[850]), // Mobil DataTable satır arka planı
        dataTextStyle: const TextStyle(color: Colors.white70), // Mobil DataTable hücre metin stili
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[700], // Mobil input alanları için dolgu rengi
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.deepOrange.shade300)
        ),
        prefixIconColor: Colors.grey[400],
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[700],
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[600]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[600]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.deepOrange.shade300)),
        )
      ),
       // Diğer mobil tema ayarları...
    );
    final ThemeData webTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.light),
      textTheme: GoogleFonts.notoSansTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
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
        // İlk yönlendirme ekranını role göre belirle
        home: isLoggedIn 
            ? (userRole == 'admin' ? const AdminMain() : const ProductListPage()) 
            : const LoginScreen(),
        routes: {
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
          '/products': (context) => const ProductListPage(),
          // '/admin': (context) => const AdminMain(), // onGenerateRoute ile yönetilecek
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/admin') {
            return MaterialPageRoute(builder: (context) => const AdminRouteGuard());
          }
          // Diğer rotalar için varsayılan işleme (routes tablosundan)
          // Eğer settings.name routes tablosunda varsa, bu blok çalışmayacak.
          // Eğer routes tablosunda yoksa ve burası null dönerse, onUnknownRoute tetiklenir.
          return null; 
        },
      ),
    );
  }
}
