import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firebase/firebase_web_stub.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/admin_topbar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  int _userCount = 0;
  int _orderCount = 0;
  double _totalRevenue = 0;
  Map<String, int> _categorySales = {};
  List<Map<String, dynamic>> _recentOrders = [];
  int _productCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('🔄 Dashboard verileri yükleniyor');
      
      // Firebase Realtime Database referanslarını oluştur
      final usersRef = FirebaseDatabase.instance.ref('users');
      final ordersRef = FirebaseDatabase.instance.ref('orders');
      final productsUrl = kIsWeb ? 'http://localhost:8000/api/products' : 'http://10.0.2.2:8000/api/products';

      // Kullanıcı sayısı
      int userCount = 0;
      final usersSnapshot = await usersRef.get();
      if (usersSnapshot.exists && usersSnapshot.value != null) {
        final users = usersSnapshot.value as Map;
        userCount = users.length;
        print('✅ ${userCount} kullanıcı bulundu');
      }

      // Sipariş sayısı ve toplam gelir
      int orderCount = 0;
      double totalRevenue = 0;
      Map<String, int> categoryCount = {};
      List<Map<String, dynamic>> recentOrders = [];
      
      final ordersSnapshot = await ordersRef.get();
      if (ordersSnapshot.exists && ordersSnapshot.value != null) {
        final orders = ordersSnapshot.value as Map;
        
        orders.forEach((key, value) {
          if (value is Map) {
            // Kullanıcı bazlı siparişler
            if (value.values.first is Map) {
              value.forEach((orderId, orderData) {
                orderCount++;
                _processOrderData(orderData as Map, categoryCount, recentOrders, orderId.toString());
                totalRevenue += double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0;
              });
            } else {
              // Doğrudan sipariş
              orderCount++;
              _processOrderData(value as Map, categoryCount, recentOrders, key.toString());
              totalRevenue += double.tryParse(value['total']?.toString() ?? '0') ?? 0.0;
            }
          }
        });
        
        print('✅ ${orderCount} sipariş bulundu, toplam gelir: $totalRevenue');
      }

      // MongoDB'den ürün sayısı
      int productCount = 0;
      try {
        print('🔄 MongoDB\'den ürün verileri yükleniyor');
        final response = await http.get(Uri.parse(productsUrl));
        
        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['products'] != null) {
            productCount = (jsonData['products'] as List).length;
            print('✅ ${productCount} ürün bulundu');
          }
        }
      } catch (e) {
        print('❌ Ürün verisi yüklenirken hata: $e');
        productCount = 0;
      }

      setState(() {
        _userCount = userCount;
        _orderCount = orderCount;
        _totalRevenue = totalRevenue;
        _categorySales = categoryCount;
        _recentOrders = recentOrders;
        _productCount = productCount;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Dashboard verileri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processOrderData(Map orderData, Map<String, int> categoryCount, List<Map<String, dynamic>> recentOrders, String orderId) {
    // Kategori satışlarını hesapla
    if (orderData['items'] is List) {
      for (var item in orderData['items']) {
        if (item is Map) {
          final category = item['category'] ?? 'diğer';
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }
    }
    
    // Son siparişleri kaydet
    if (recentOrders.length < 5) {
      recentOrders.add({
        'id': orderId,
        'date': orderData['orderDate'] ?? 'Tarih Yok',
        'total': double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0,
        'status': orderData['status'] ?? 'Beklemede',
      });
    }
  }

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
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRecentOrdersCard(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLowStockCard(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Satış İstatistikleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _categorySales.isEmpty
                              ? Center(
                                  child: Text(
                                    'Veri yok',
                                    style: GoogleFonts.montserrat(color: Colors.grey),
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sections: _getCategorySections(),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          'Toplam Satış',
          '₺${_totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Yeni Siparişler',
          _orderCount.toString(),
          Icons.shopping_bag,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Toplam Ürün',
          _productCount.toString(),
          Icons.inventory,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Müşteriler',
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
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Siparişler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Sipariş #${order['id'].toString().substring(0, 8)}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    order['date'],
                    style: GoogleFonts.montserrat(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  trailing: _getStatusChip(index),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Tüm siparişleri görüntüleme işlemi
              },
              child: const Text('Tüm siparişleri görüntüle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusChip(int index) {
    final statuses = [
      {'text': 'Teslim Edildi', 'color': Colors.green},
      {'text': 'İşleniyor', 'color': Colors.blue},
      {'text': 'Kargoda', 'color': Colors.orange},
      {'text': 'Beklemede', 'color': Colors.amber},
      {'text': 'İptal Edildi', 'color': Colors.red},
    ];
    
    final status = statuses[index % statuses.length];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: status['color'] as Color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status['text'] as String,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Düşük Stok Uyarısı',
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
                    '${stockCounts[index]} adet kaldı',
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

  List<PieChartSectionData> _getCategorySections() {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    int total = _categorySales.values.fold(0, (a, b) => a + b);
    
    return _categorySales.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final count = entry.value.value;
      final percent = total > 0 ? count / total : 0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: count.toDouble(),
        title: '${(percent * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
} 