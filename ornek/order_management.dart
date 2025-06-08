import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase/firebase_web_stub.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔄 Firebase\'den siparişler yükleniyor');
      
      if (!kIsWeb) {
        // Native platforms - gerçek Firebase kullan
        final ordersRef = FirebaseDatabase.instance.ref('orders');
        final snapshot = await ordersRef.get();
        
        if (snapshot.exists && snapshot.value != null) {
          final ordersData = snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> ordersList = [];
          
          ordersData.forEach((key, value) {
            if (value is Map) {
              // Kullanıcı bazlı siparişler
              if (value.values.first is Map) {
                value.forEach((orderId, orderData) {
                  ordersList.add(_mapOrderData(orderId.toString(), orderData as Map));
                });
              } else {
                // Doğrudan sipariş
                ordersList.add(_mapOrderData(key.toString(), value as Map));
              }
            }
          });
          
          setState(() {
            _orders = ordersList;
            _isLoading = false;
          });
          print('✅ ${_orders.length} adet sipariş Firebase\'den yüklendi');
        } else {
          print('ℹ️ Firebase\'den sipariş bulunamadı');
          _loadDemoOrders();
        }
      } else {
        print('ℹ️ Web platformunda Firebase simülasyonu kullanılıyor');
        _loadDemoOrders();
      }
    } catch (e) {
      print('❌ Firebase sipariş yüklenirken hata: $e');
      setState(() {
        _errorMessage = 'Siparişler yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
      _loadDemoOrders();
    }
  }

  Map<String, dynamic> _mapOrderData(String id, Map orderData) {
    return {
      'id': id,
      'customer': orderData['customerName'] ?? 'İsimsiz Müşteri',
      'date': orderData['orderDate'] ?? DateTime.now().toString(),
      'total': double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0,
      'status': orderData['status'] ?? 'Beklemede',
      'products': orderData['items'] ?? [],
      'address': orderData['deliveryAddress'] ?? 'Adres bilgisi yok',
      'payment': orderData['paymentMethod'] ?? 'Ödeme bilgisi yok',
    };
  }

  void _loadDemoOrders() {
    print('⚠️ Demo sipariş verileri yükleniyor');
    setState(() {
      _orders = [
        {
          'id': '1001',
          'customer': 'Ahmet Yılmaz',
          'date': '2023-10-15 14:30',
          'total': 148.75,
          'status': 'Teslim Edildi',
          'products': [
            {'name': 'Elma', 'quantity': 2, 'price': 9.99},
            {'name': 'Süt', 'quantity': 3, 'price': 12.25},
            {'name': 'Ekmek', 'quantity': 2, 'price': 5.00},
          ],
          'address': 'Bahçelievler Mah. 123 Sk. No: 5 İstanbul',
          'payment': 'Kredi Kartı',
        },
        {
          'id': '1002',
          'customer': 'Ayşe Demir',
          'date': '2023-10-16 10:15',
          'total': 256.50,
          'status': 'Kargoya Verildi',
          'products': [
            {'name': 'Patates', 'quantity': 5, 'price': 8.50},
            {'name': 'Tavuk', 'quantity': 1, 'price': 85.50},
            {'name': 'Yumurta', 'quantity': 2, 'price': 24.99},
          ],
          'address': 'Ataşehir Mah. 45 Sk. No: 12 İstanbul',
          'payment': 'Nakit',
        },
        {
          'id': '1003',
          'customer': 'Mehmet Yıldız',
          'date': '2023-10-16 16:45',
          'total': 89.95,
          'status': 'Hazırlanıyor',
          'products': [
            {'name': 'Domates', 'quantity': 3, 'price': 7.50},
            {'name': 'Peynir', 'quantity': 1, 'price': 45.75},
            {'name': 'Su', 'quantity': 2, 'price': 4.99},
          ],
          'address': 'Kadıköy Mah. 78 Sk. No: 18/3 İstanbul',
          'payment': 'Kredi Kartı',
        },
        {
          'id': '1004',
          'customer': 'Fatma Çelik',
          'date': '2023-10-17 09:20',
          'total': 175.60,
          'status': 'Onay Bekliyor',
          'products': [
            {'name': 'Elma', 'quantity': 2, 'price': 9.99},
            {'name': 'Süt', 'quantity': 2, 'price': 12.25},
            {'name': 'Pirinç', 'quantity': 1, 'price': 35.40},
            {'name': 'Makarna', 'quantity': 3, 'price': 8.99},
            {'name': 'Şeker', 'quantity': 1, 'price': 27.75},
          ],
          'address': 'Beşiktaş Mah. 34 Sk. No: 7/4 İstanbul',
          'payment': 'Kapıda Ödeme',
        },
      ];
      _isLoading = false;
    });
  }

  // Firebase'de sipariş durumunu güncelle
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      print('🔄 Sipariş durumu güncelleniyor: $orderId, yeni durum: $status');
      
      if (!kIsWeb) {
        // Native platforms - gerçek Firebase kullan
        final ordersRef = FirebaseDatabase.instance.ref('orders');
        
        // Önce siparişi bul
        final snapshot = await ordersRef.get();
        if (snapshot.exists && snapshot.value != null) {
          final ordersData = snapshot.value as Map<dynamic, dynamic>;
          String? path;
          
          // Siparişi bulmaya çalış
          ordersData.forEach((key, value) {
            if (value is Map) {
              // Kullanıcı bazlı siparişlerde ara
              if (value.containsKey(orderId)) {
                path = 'orders/$key/$orderId';
              }
              // Doğrudan siparişlerde ara
              else if (key.toString() == orderId) {
                path = 'orders/$key';
              }
            }
          });
          
          if (path != null) {
            await FirebaseDatabase.instance.ref(path!).update({'status': status});
            print('✅ Sipariş durumu Firebase\'de güncellendi');
          } else {
            print('❌ Sipariş bulunamadı: $orderId');
            throw Exception('Sipariş bulunamadı');
          }
        }
      } else {
        print('ℹ️ Web platformunda demo sipariş güncelleniyor');
        // Demo sipariş güncelle
        setState(() {
          final index = _orders.indexWhere((o) => o['id'] == orderId);
          if (index != -1) {
            _orders[index]['status'] = status;
          }
        });
      }
      
      // Siparişleri yeniden yükle
      await _fetchOrders();
    } catch (e) {
      print('❌ Sipariş durumu güncellenirken hata: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sipariş Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _fetchOrders();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildOrdersTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Sipariş ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          hint: const Text('Durum'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tümü')),
            DropdownMenuItem(value: 'delivered', child: Text('Teslim Edildi')),
            DropdownMenuItem(value: 'shipped', child: Text('Kargoya Verildi')),
            DropdownMenuItem(value: 'processing', child: Text('Hazırlanıyor')),
            DropdownMenuItem(value: 'pending', child: Text('Onay Bekliyor')),
          ],
          onChanged: (value) {
            // Filter orders by status
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            // Show date picker for filtering by date
          },
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Sipariş No')),
              DataColumn(label: Text('Müşteri')),
              DataColumn(label: Text('Tarih')),
              DataColumn(label: Text('Toplam')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: _orders.map((order) {
              return DataRow(cells: [
                DataCell(Text('#${order['id']}')),
                DataCell(Text(order['customer'])),
                DataCell(Text(order['date'])),
                DataCell(
                  Text(
                    NumberFormat.currency(
                      locale: 'tr',
                      symbol: '₺',
                      decimalDigits: 2,
                    ).format(order['total']),
                  ),
                ),
                DataCell(_buildStatusBadge(order['status'])),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        _showOrderDetails(context, order);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showUpdateStatusDialog(context, order);
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    
    switch (status) {
      case 'Teslim Edildi':
        color = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        break;
      case 'Kargoya Verildi':
        color = Colors.blue;
        bgColor = Colors.blue.withOpacity(0.1);
        break;
      case 'Hazırlanıyor':
        color = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.1);
        break;
      case 'Onay Bekliyor':
        color = Colors.purple;
        bgColor = Colors.purple.withOpacity(0.1);
        break;
      case 'İptal Edildi':
        color = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sipariş #${order['id']} Detayları'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Müşteri', order['customer']),
                _buildInfoRow('Tarih', order['date']),
                _buildInfoRow('Durum', order['status']),
                _buildInfoRow('Adres', order['address']),
                _buildInfoRow('Ödeme', order['payment']),
                const SizedBox(height: 16),
                const Text(
                  'Sipariş Ürünleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: (order['products'] as List).length,
                    itemBuilder: (context, index) {
                      final product = (order['products'] as List)[index];
                      return ListTile(
                        dense: true,
                        title: Text(product['name']),
                        subtitle: Text('${product['quantity']} adet'),
                        trailing: Text(
                          NumberFormat.currency(
                            locale: 'tr',
                            symbol: '₺',
                            decimalDigits: 2,
                          ).format(product['price'] * product['quantity']),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Toplam: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'tr',
                        symbol: '₺',
                        decimalDigits: 2,
                      ).format(order['total']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, Map<String, dynamic> order) {
    String selectedStatus = order['status'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sipariş #${order['id']} Durumu Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Durum'),
                items: const [
                  DropdownMenuItem(value: 'Onay Bekliyor', child: Text('Onay Bekliyor')),
                  DropdownMenuItem(value: 'Hazırlanıyor', child: Text('Hazırlanıyor')),
                  DropdownMenuItem(value: 'Kargoya Verildi', child: Text('Kargoya Verildi')),
                  DropdownMenuItem(value: 'Teslim Edildi', child: Text('Teslim Edildi')),
                  DropdownMenuItem(value: 'İptal Edildi', child: Text('İptal Edildi')),
                ],
                onChanged: (value) {
                  selectedStatus = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  await _updateOrderStatus(order['id'], selectedStatus);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Durum güncellenirken hata: $e')),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }
} 