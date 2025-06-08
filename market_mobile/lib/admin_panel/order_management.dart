import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // math.min için eklendi
import 'package:flutter/foundation.dart' show kIsWeb; // EKLENDİ
// import '../firebase/firebase_web_stub.dart'; // Yorumlandı
// import 'dart:convert'; // Servis içinde kullanılmıyorsa gereksiz
// import 'package:http/http.dart' as http; // Servis içinde kullanılmıyorsa gereksiz
import 'services/admin_order_service.dart'; // Yeni sipariş servisi
// import 'package:firebase_database/firebase_database.dart'; // Geçici olarak status güncelleme dialoğu için -> KALDIRILDI

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  final AdminOrderService _orderService = AdminOrderService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = []; // Arama için
  String _errorMessage = '';
  TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter; // Filtre için seçilen durum

  // Olası sipariş durumları (backend'deki ile uyumlu olmalı)
  final List<String> _orderStatuses = ['active', 'completed', 'cancelled', 'preparing', 'shipped', 'pending'];
  // Kullanıcıya gösterilecek durum isimleri (isteğe bağlı)
  final Map<String, String> _statusDisplayNames = {
    'active': 'Aktif',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal Edildi',
    'preparing': 'Hazırlanıyor',
    'shipped': 'Kargoda',
    'pending': 'Onay Bekliyor',
    'all': 'Tümü' // Filtre için özel
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOrders);
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // _selectedStatusFilter "all" ise filtre gönderme (null)
      final String? statusToFetch = (_selectedStatusFilter == 'all' || _selectedStatusFilter == null) ? null : _selectedStatusFilter;
      _orders = await _orderService.fetchOrders(statusFilter: statusToFetch);
      _filterOrders(); // Arama ve filtrelemeyi uygula
      print('OrderManagement: ${_orders.length} sipariş servisten yüklendi (filtre: $statusToFetch). Sonuç: ${_filteredOrders.length}');
    } catch (e) {
      print('OrderManagement: Sipariş yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Siparişler yüklenirken bir hata oluştu: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterOrders() {
    List<Map<String, dynamic>> tempOrders = List.from(_orders);
    String searchTerm = _searchController.text.toLowerCase();

    if (searchTerm.isNotEmpty) {
      tempOrders = tempOrders.where((order) {
        final orderNumber = order['orderNumber']?.toString().toLowerCase() ?? '';
        final customerName = order['customerName']?.toString().toLowerCase() ?? '';
        final customerEmail = order['customerEmail']?.toString().toLowerCase() ?? '';
        return orderNumber.contains(searchTerm) || 
               customerName.contains(searchTerm) ||
               customerEmail.contains(searchTerm);
      }).toList();
    }
    // Status filter zaten _fetchOrders içinde API katmanında yapılıyor,
    // ama client-side arama sonrası tekrar tüm listeyi göstermek için _orders kullanılır.
    // Eğer API'den tümü çekilip client'da status filter yapılacaksa buraya eklenebilir.
    // Mevcut durumda API zaten filtreli getirdiği için _orders her zaman filtrelidir (ya da tümü).
    // Bu yüzden _searchController listener'ı _orders üzerinde çalışır.

    setState(() {
      _filteredOrders = tempOrders;
    });
  }
  
  Future<void> _updateOrderStatus(String customerUserId, String firebaseOrderId, String newStatus) async {
    try {
      bool success = await _orderService.updateOrderStatus(customerUserId, firebaseOrderId, newStatus);
      if (success && mounted) {
        print('OrderManagement: Sipariş durumu başarıyla güncellendi.');
        await _fetchOrders(); // Listeyi yenile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sipariş (#${firebaseOrderId.substring(0, math.min(6, firebaseOrderId.length))}...) durumu $newStatus olarak güncellendi.'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sipariş durumu güncellenemedi (servisten false döndü).'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      print('OrderManagement: Sipariş durumu güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sipariş durumu güncellenemedi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersTable(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Sipariş No, Müşteri Adı/Email ile ara...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Duruma Göre Filtrele',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _selectedStatusFilter ?? 'all',
          hint: const Text('Durum Seçin'),
          isExpanded: true,
          items: ['all', ..._orderStatuses].map((status) { // 'all' seçeneğini ekle
            return DropdownMenuItem<String>(
              value: status,
              child: Text(_statusDisplayNames[status] ?? status),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatusFilter = value;
            });
            _fetchOrders(); // Filtre değiştiğinde siparişleri yeniden yükle
          },
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }
    if (_filteredOrders.isEmpty && !_isLoading) {
      return const Center(child: Text('Gösterilecek sipariş bulunamadı.', style: TextStyle(fontSize: 16)));
    }

    // Web için özel başlık rengi, mobil için temadan alacak
    final MaterialStateProperty<Color?>? headingRowColor = kIsWeb 
        ? MaterialStateProperty.resolveWith((states) => Colors.blueGrey.shade50)
        : null; // Mobil için null bırakarak DataTableTheme'dan almasını sağla

    // Web için özel başlık metin stili, mobil için temadan alacak
    final TextStyle? headingTextStyle = kIsWeb 
        ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87) // Web için siyah
        : null; // Mobil için null bırakarak DataTableTheme'dan almasını sağla

    // Web için özel data metin stili, mobil için temadan alacak
    final TextStyle? dataTextStyle = kIsWeb 
        ? const TextStyle(color: Colors.black87) // Web için siyah
        : null; // Mobil için null bırakarak DataTableTheme'dan almasını sağla

    return Card(
      // Card'ın rengi mobil temadan (CardTheme) gelecek.
      // Web teması için CardTheme tanımlanmadıysa, varsayılan light tema Card rengini kullanır.
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView( // Yatay kaydırma için
        scrollDirection: Axis.horizontal,
        child: DataTable(
            columnSpacing: 20,
            headingRowColor: headingRowColor, // Platforma göre ayarlandı
            // headingTextStyle: headingTextStyle, // DataTableThemeData içinde ayarlandığı için burada yoruma alınabilir veya platforma göre koşullandırılabilir
            // dataTextStyle: dataTextStyle, // DataTableThemeData içinde ayarlandığı için burada yoruma alınabilir veya platforma göre koşullandırılabilir
            columns: [
              DataColumn(label: Text('Sipariş No', style: headingTextStyle)), // Stil platforma göre ayarlandı
              DataColumn(label: Text('Müşteri', style: headingTextStyle)),
              DataColumn(label: Text('Tarih', style: headingTextStyle)),
              DataColumn(label: Text('Tutar', style: headingTextStyle)),
              DataColumn(label: Text('Durum', style: headingTextStyle)),
              DataColumn(label: Text('İşlemler', style: headingTextStyle)),
            ],
            rows: _filteredOrders.map((order) {
              final timestamp = order['timestamp'];
              String formattedDate = 'Bilinmiyor';
              if (timestamp != null && timestamp is num) {
                try {
                   formattedDate = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(
                    DateTime.fromMillisecondsSinceEpoch(timestamp.toInt())
                  );
                } catch (e) {
                  print("Tarih formatlama hatası: $e, timestamp: $timestamp");
                }
              }
              
              final totalPrice = order['totalPrice'];
              String formattedPrice = '-';
              if (totalPrice != null && totalPrice is num) {
                formattedPrice = '₺${totalPrice.toStringAsFixed(2)}';
              }

              String orderStatus = order['status'] ?? 'bilinmiyor';
              String displayStatus = _statusDisplayNames[orderStatus] ?? orderStatus.capitalizeFirstLetter();

              // DataCell içindeki Text widgetları için platforma göre stil
              Widget dataCellText(String text) {
                return Text(text, style: dataTextStyle);
              }

              return DataRow(
                // Satır renkleri de DataTableTheme'dan gelebilir
                cells: [
                  DataCell(dataCellText(order['orderNumber'] ?? 'N/A')),
                  DataCell(dataCellText(order['customerName'] ?? 'N/A')),
                  DataCell(dataCellText(formattedDate)),
                  DataCell(dataCellText(formattedPrice)),
                  DataCell(_buildStatusChip(orderStatus, displayStatus)), // Chip kendi stilini yönetir
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                        tooltip: 'Sipariş Detaylarını Görüntüle',
                        onPressed: () {
                          _showOrderDetails(context, order);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                        tooltip: 'Sipariş Durumunu Güncelle',
                        onPressed: () {
                          // customerUserId ve firebaseOrderId'yi servise göndereceğiz
                          final String custId = order['customerUserId']?.toString() ?? '';
                          final String fbOrderId = order['firebaseOrderId']?.toString() ?? '';
                          if (custId.isNotEmpty && fbOrderId.isNotEmpty) {
                            _showUpdateStatusDialog(context, custId, fbOrderId, order['status']?.toString() ?? '');
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sipariş ID veya Müşteri ID bulunamadı!'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String displayText) {
    Color color;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'tamamlandı':
        color = Colors.green;
        break;
      case 'active':
      case 'aktif':
        color = Colors.blue;
        break;
      case 'shipped':
      case 'kargoda':
        color = Colors.teal;
        break;
      case 'preparing':
      case 'hazırlanıyor':
        color = Colors.orange;
        break;
      case 'pending':
      case 'onay bekliyor':
        color = Colors.purple;
        break;
      case 'cancelled':
      case 'iptal edildi':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        displayText,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    // Backend'den gelen AdminOrderResponse yapısına göre verileri alalım
    final String orderNumber = order['orderNumber']?.toString() ?? 'N/A';
    final String customerName = order['customerName']?.toString() ?? 'Bilinmiyor';
    final String customerEmail = order['customerEmail']?.toString() ?? 'Bilinmiyor';
    final String paymentMethod = order['paymentMethod']?.toString() ?? 'Belirtilmemiş';
    final String currentStatus = order['status']?.toString() ?? 'Bilinmiyor';
    final double totalPrice = (order['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final timestamp = order['timestamp'];
    String formattedDate = 'Bilinmiyor';
    if (timestamp != null && timestamp is num) {
      try {
        formattedDate = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(
          DateTime.fromMillisecondsSinceEpoch(timestamp.toInt())
        );
      } catch (e) { /* Hata olursa formattedDate 'Bilinmiyor' kalır */ }
    }

    final List<dynamic> productsRaw = order['products'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> products = productsRaw.map((p) => p as Map<String, dynamic>).toList();

    final Map<String, dynamic>? addressRaw = order['address'] as Map<String, dynamic>?;
    String fullAddress = "Adres bilgisi yok";
    if (addressRaw != null) {
      fullAddress = "${addressRaw['title'] ?? ''}: ${addressRaw['full'] ?? 'Detay yok'}\nMahalle: ${addressRaw['mahalle'] ?? 'N/A'}, Bina: ${addressRaw['binaNo'] ?? 'N/A'}, Kat: ${addressRaw['kat'] ?? 'N/A'}, Daire: ${addressRaw['daireNo'] ?? 'N/A'}\nTarif: ${addressRaw['tarif'] ?? ''}".trim();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sipariş Detayları (#$orderNumber)'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('Müşteri Adı', customerName),
                _buildDetailRow('Müşteri Email', customerEmail),
                _buildDetailRow('Sipariş Tarihi', formattedDate),
                _buildDetailRow('Toplam Tutar', NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(totalPrice)),
                _buildDetailRow('Ödeme Yöntemi', paymentMethod),
                _buildDetailRow('Mevcut Durum', _statusDisplayNames[currentStatus.toLowerCase()] ?? currentStatus),
                const SizedBox(height: 10),
                Text('Adres Bilgileri:', style: Theme.of(context).textTheme.titleMedium),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(fullAddress, style: Theme.of(context).textTheme.bodyMedium),
                ),
                const SizedBox(height: 10),
                Text('Ürünler (${products.length}):', style: Theme.of(context).textTheme.titleMedium),
                if (products.isNotEmpty)
                  SizedBox(
                    height: 150, // Ürün listesi için sabit yükseklik veya ListView.shrinkWrap
                    child: SingleChildScrollView( // ListView.builder yerine Column ve scroll
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: products.map((product) {
                          final productName = product['name']?.toString() ?? 'Bilinmeyen Ürün';
                          final quantity = (product['quantity'] as num?)?.toInt() ?? 0;
                          final price = (product['price'] as num?)?.toDouble() ?? 0.0;
                          final productTotalPrice = quantity * price;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(child: Text((products.indexOf(product) + 1).toString())),
                            title: Text(productName),
                            subtitle: Text('$quantity adet x ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(price)}'),
                            trailing: Text(NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(productTotalPrice)),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  const Text('Bu siparişte ürün bulunmamaktadır.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, String customerUserId, String firebaseOrderId, String currentStatus) {
    String selectedStatus = currentStatus; // Başlangıçta mevcut durum seçili
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sipariş Durumunu Güncelle (#${firebaseOrderId.substring(0, math.min(6, firebaseOrderId.length))})'),
          content: StatefulBuilder( // DropdownButton'ın state'ini yönetmek için
            builder: (BuildContext context, StateSetter setStateDialog) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Yeni Durum',
                  border: OutlineInputBorder(),
                ),
                value: selectedStatus,
                items: _orderStatuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(_statusDisplayNames[status] ?? status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setStateDialog(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Güncelle'),
              onPressed: () {
                if (selectedStatus.isNotEmpty && selectedStatus != currentStatus) {
                  Navigator.of(context).pop(); // Dialogu kapat
                  _updateOrderStatus(customerUserId, firebaseOrderId, selectedStatus);
                } else if (selectedStatus == currentStatus) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni durum mevcut durumla aynı.'), backgroundColor: Colors.orange),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// String için capitalizeFirstLetter extension metodu
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (this.isEmpty) return "";
    if (this.length == 1) return this.toUpperCase();
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
} 