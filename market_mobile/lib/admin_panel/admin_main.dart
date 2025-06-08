import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import '../firebase/firebase_web_stub.dart'; // Bu import şimdilik yorum satırı yapıldı
import 'package:market_mobile/admin_panel/sidebar.dart';
import 'package:market_mobile/admin_panel/topbar.dart';
import 'package:market_mobile/admin_panel/admin_dashboard.dart';
import 'package:market_mobile/admin_panel/user_management.dart';
import 'package:market_mobile/admin_panel/product_management.dart';
import 'package:market_mobile/admin_panel/order_management.dart';
import 'package:market_mobile/admin_panel/stock_management.dart';
import 'package:market_mobile/screens/login_screen.dart'; // Import yolu düzeltildi
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth için import eklendi
import 'package:market_mobile/services/auth_service.dart'; // AuthService import edildi

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _selectedIndex = 0;
  
  // Admin panelindeki sayfalar
  late List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // Hata ayıklama bilgisi yazdır
    print("Admin paneli baslatiliyor");
    
    // Sayfaları başlat
    _pages = [
      const AdminDashboard(),
      const UserManagement(),
      const ProductManagement(),
      const OrderManagement(),
      const StockManagement(),
    ];
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("Admin paneli sayfasi degisti: $_selectedIndex");
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800 && screenWidth <= 1200;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AdminTopBar(title: _getTitle()),
      ),
      drawer: isLargeScreen ? null : AdminSidebar(
        selectedIndex: _selectedIndex,
        onItemTap: _onItemTapped,
      ),
      body: Row(
        children: [
          if (isLargeScreen || isMediumScreen)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onItemTap: _onItemTapped,
              isExpanded: isLargeScreen,
            ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
  
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Kullanıcı Yönetimi';
      case 2:
        return 'Ürün Yönetimi';
      case 3:
        return 'Sipariş Yönetimi';
      case 4:
        return 'Stok Yönetimi';
      default:
        return 'Admin Panel';
    }
  }

  Future<void> _logout() async {
    try {
      // Firebase'den çıkış yap (mobil ve web için farklı olabilir, kIsWeb kontrolü önemli)
      if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
          print("AdminMain: Firebase'den cikis yapildi.");
      }
      
      // SharedPreferences'taki yetkilendirme verilerini temizle
      await AuthService.clearAuthData();
      print('AdminMain: Yetkilendirme verileri temizlendi.');
      
      if (mounted) {
        // Login ekranına yönlendir ve geri gelmeyi engelle
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('AdminMain: Cikis yapilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cikis yapilirken bir hata olustu: $e')),
        );
      }
    }
  }
} 