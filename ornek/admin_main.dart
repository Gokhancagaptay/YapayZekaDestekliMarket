import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase/firebase_web_stub.dart';
import 'sidebar.dart';
import 'topbar.dart';
import 'admin_dashboard.dart';
import 'user_management.dart';
import 'product_management.dart';
import 'order_management.dart';
import 'stock_management.dart';
import '../screens/login_screen.dart';

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
    print("⚙️ Admin paneli başlatılıyor");
    
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
      print("🔄 Admin paneli sayfası değişti: $_selectedIndex");
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
      if (!kIsWeb) {
        await FirebaseAuth.instance.signOut();
      }
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken bir hata oluştu: $e')),
        );
      }
    }
  }
} 