import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../firebase/firebase_web_stub.dart'; // Bu import şimdilik yorum satırı yapıldı
import 'package:fl_chart/fl_chart.dart';
import 'package:market_mobile/admin_panel/widgets/admin_topbar.dart'; // Import yolu düzeltildi
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:firebase_database/firebase_database.dart'; // Tamamen kaldırıldı
import 'services/admin_dashboard_service.dart'; // Yeni servis import edildi

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  int _userCount = 0;
  double _completedOrdersRevenue = 0;
  int _activeOrderCount = 0;
  // Map<String, int> _categorySales = {}; // API'den gelmiyorsa kaldırılabilir veya dummy bırakılabilir
  // List<Map<String, dynamic>> _recentOrders = []; // API'den gelmiyorsa kaldırılabilir veya dummy bırakılabilir
  int _productCount = 0;

  final AdminDashboardService _dashboardService = AdminDashboardService(); // Servis örneği oluşturuldu

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('🔄 Dashboard verileri API_den yukleniyor - Baslangic');
      
      final stats = await _dashboardService.fetchDashboardStats();
      _completedOrdersRevenue = stats['totalCompletedRevenue']?.toDouble() ?? 0.0;
      _activeOrderCount = stats['activeOrdersCount']?.toInt() ?? 0;
      _userCount = stats['totalUsers']?.toInt() ?? 0; // Kullanıcı sayısı API'den alındı

      print('✅ API_den gelen stats: Tamamlanmis Gelir: $_completedOrdersRevenue, Aktif Siparisler: $_activeOrderCount, Kullanicilar: $_userCount');

      try {
        print('  MongoDB_den urun verileri API_den yukleniyor...');
        final productsUrl = kIsWeb ? 'http://localhost:8000/api/products' : 'http://10.0.2.2:8000/api/products';
        final response = await http.get(Uri.parse(productsUrl)); 
        if (response.statusCode == 200) {
          final List<dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes)); // Direkt liste olarak al
          _productCount = jsonData.length; // Listenin uzunluğunu al
          print('  ✅ ${_productCount} urun bulundu');
        } else {
          print('  ❌ MongoDB urun yukleme hatasi - Status Code: ${response.statusCode}');
          _productCount = 0;
        }
      } catch (e) {
        print('  ❌ MongoDB urun yuklerken hata: $e');
        _productCount = 0;
      }

      setState(() {
        _isLoading = false;
        print('🔄 Dashboard verileri yuklendi ve state guncellendi - Son');
      });
    } catch (e, s) {
      print('❌ _loadDashboardData GENEL HATA: $e');
      print('  Stack trace: $s');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // _processOrderData fonksiyonu artık kullanılmayacak çünkü hesaplamalar backend'de yapılıyor.
  // void _processOrderData(Map orderData, Map<String, int> categoryCount, List<Map<String, dynamic>> recentOrders, String orderId) { ... }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(context),
            const SizedBox(height: 24),
            
            // Satış İstatistikleri ve Son Siparişler kartları API'den veri gelene kadar geçici olarak kaldırıldı
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Expanded(
            //       flex: 2,
            //       child: _buildRecentOrdersCard(context), // Hata veriyor çünkü _recentOrders yok
            //     ),
            //     const SizedBox(width: 16),
            //     Expanded(
            //       child: _buildLowStockCard(context), // Bu kart dummy veri kullanıyor, kalabilir
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 24),
            // Card(
            //   child: Container(
            //     width: double.infinity,
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text(
            //           'Satış İstatistikleri',
            //           style: TextStyle(
            //             fontSize: 18,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         const SizedBox(height: 16),
            //         Container(
            //           height: 300,
            //           alignment: Alignment.center,
            //           child: _isLoading
            //               ? const CircularProgressIndicator()
            //               : (_categorySales.isEmpty // Hata veriyor çünkü _categorySales yok
            //                   ? Center(
            //                       child: Text(
            //                         'Veri yok',
            //                         style: GoogleFonts.montserrat(color: Colors.grey),
            //                       ),
            //                     )
            //                   : PieChart(
            //                       PieChartData(
            //                         sections: _getCategorySections(), // Hata veriyor
            //                         centerSpaceRadius: 40,
            //                         sectionsSpace: 2,
            //                       ),
            //                     )),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final int crossAxisCount = kIsWeb ? 4 : 2;
    final double childAspectRatio = kIsWeb ? 1.8 : 1.6; // Mobil için en-boy oranı 1.5'ten 1.6'ya çıkarıldı

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio, // En boy oranını ayarlayarak mobil görünümü iyileştirme
      children: [
        _buildStatCard(
          context,
          'Toplam Satis',
          '₺${_completedOrdersRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Yeni Siparisler',
          _activeOrderCount.toString(),
          Icons.shopping_bag,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Toplam Urun',
          _productCount.toString(),
          Icons.inventory,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Musteriler',
          _userCount.toString(),
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final double cardPadding = kIsWeb ? 16.0 : 12.0; // Mobil için padding azaltıldı
    final double internalSpacing = kIsWeb ? 12.0 : 8.0; // Mobil için boşluk azaltıldı

    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: kIsWeb ? null : 13, // Mobil için başlık fontu biraz küçültüldü
                  ),
                ),
                Icon(icon, color: color, size: kIsWeb ? null : 20), // Mobil için ikon boyutu biraz küçültüldü
              ],
            ),
            SizedBox(height: internalSpacing),
            Text(
              value,
              style: TextStyle(
                fontSize: kIsWeb ? 24 : 20, // Mobil için değer fontu biraz küçültüldü
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildRecentOrdersCard ve _getCategorySections fonksiyonları _recentOrders ve _categorySales kullanıyor,
  // bu değişkenler kaldırıldığı için bu widget'lar da geçici olarak build metodundan kaldırıldı.
  // Eğer bu kartlar gösterilmek isteniyorsa, API'den veri çekilmeli veya dummy data ile doldurulmalı.

  // Widget _buildRecentOrdersCard(BuildContext context) { ... }
  // List<PieChartSectionData> _getCategorySections() { ... }
  
  Widget _buildLowStockCard(BuildContext context) { // Bu kart dummy veri kullandığı için kalabilir
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dusuk Stok Uyarisi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final productNames = ['Elma', 'Armut', 'Patates', 'Biber'];
                final stockCounts = [3, 4, 2, 5];
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(productNames[index]),
                  trailing: Text(
                    '${stockCounts[index]} adet kaldi',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 