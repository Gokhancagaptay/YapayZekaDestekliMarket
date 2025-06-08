import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firebase/firebase_web_stub.dart';
import 'widgets/admin_topbar.dart';
import 'widgets/admin_table.dart';
import 'package:intl/intl.dart';

class AdminOrderManagement extends StatefulWidget {
  const AdminOrderManagement({Key? key}) : super(key: key);

  @override
  State<AdminOrderManagement> createState() => _AdminOrderManagementState();
}

class _AdminOrderManagementState extends State<AdminOrderManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _searchQuery = '';
  String _statusFilter = 'Tümü';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusOptions = ['Tümü', 'Beklemede', 'İşleniyor', 'Tamamlandı', 'İptal'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('orders');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> ordersMap = snapshot.value as Map;
        
        List<Map<String, dynamic>> ordersList = [];
        
        ordersMap.forEach((key, value) {
          if (value is Map) {
            // Sipariş detaylarını al
            final Map<String, dynamic> orderDetails = {
              'id': key,
              'userId': value['userId'] ?? '',
              'userName': value['userName'] ?? 'İsimsiz Kullanıcı',
              'date': value['date'] ?? DateTime.now().toIso8601String(),
              'total': (value['total'] ?? 0.0).toDouble(),
              'status': value['status'] ?? 'Beklemede',
              'address': value['address'] ?? {},
            };
            
            // Sipariş öğelerini al
            if (value['items'] is List) {
              final List<dynamic> items = value['items'];
              orderDetails['items'] = items.map((item) {
                if (item is Map) {
                  return {
                    'id': item['id'] ?? '',
                    'name': item['name'] ?? '',
                    'price': (item['price'] ?? 0.0).toDouble(),
                    'quantity': (item['quantity'] ?? 1).toInt(),
                    'image': item['image'] ?? '',
                  };
                }
                return {};
              }).toList();
            } else {
              orderDetails['items'] = [];
            }
            
            ordersList.add(orderDetails);
          }
        });
        
        // Tarihe göre sırala (en yeniler önce)
        ordersList.sort((a, b) {
          final DateTime dateA = DateTime.tryParse(a['date'].toString()) ?? DateTime.now();
          final DateTime dateB = DateTime.tryParse(b['date'].toString()) ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        
        setState(() {
          _orders = ordersList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Siparişler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _orders;
    
    // Durum filtresi
    if (_statusFilter != 'Tümü') {
      filtered = filtered.where((order) => 
        order['status'].toString().toLowerCase() == _statusFilter.toLowerCase()
      ).toList();
    }
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        return order['id'].toString().toLowerCase().contains(query) ||
               order['userName'].toString().toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseDatabase.instance
          .ref('orders/$orderId')
          .update({'status': newStatus});
          
      setState(() {
        final index = _orders.indexWhere((order) => order['id'] == orderId);
        if (index != -1) {
          _orders[index]['status'] = newStatus;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş durumu güncellendi')),
      );
    } catch (e) {
      print('Sipariş durumu güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi, lütfen tekrar deneyin')),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateTime.parse(dateStr);
      final DateFormat formatter = DateFormat('dd.MM.yyyy HH:mm');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'tamamlandı':
        return Colors.green;
      case 'beklemede':
        return Colors.orange;
      case 'işleniyor':
        return Colors.blue;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showOrderDetails(Map<String, dynamic> order) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF333333),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş #${order['id'].toString().substring(0, 8)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order['date'].toString()),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order['status']),
                          color: _getStatusColor(order['status']),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order['status'],
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order['status']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF444444), height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Müşteri Bilgileri',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow(Icons.person, 'İsim', order['userName']),
                        _detailRow(Icons.account_circle, 'Kullanıcı ID', order['userId']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teslimat Adresi',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (order['address'] is Map) ...[
                          _detailRow(
                            Icons.location_on, 
                            'Adres', 
                            order['address']['address'] ?? 'Adres belirtilmedi'
                          ),
                          if (order['address']['city'] != null)
                            _detailRow(Icons.location_city, 'Şehir', order['address']['city']),
                        ] else
                          _detailRow(Icons.location_off, 'Adres', 'Adres bilgisi yok'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Sipariş Özeti',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: (order['items'] as List).length,
                    itemBuilder: (context, index) {
                      final item = (order['items'] as List)[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: item['image'] != null && item['image'].toString().isNotEmpty
                                ? Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey[700],
                                      child: const Icon(Icons.image, color: Colors.white),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[700],
                                    child: const Icon(Icons.image, color: Colors.white),
                                  ),
                          ),
                        ),
                        title: Text(
                          item['name'] ?? 'Ürün adı yok',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '₺${(item['price'] ?? 0).toStringAsFixed(2)} x ${item['quantity'] ?? 1}',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          '₺${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Durum Güncelle',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: order['status'],
                          dropdownColor: const Color(0xFF424242),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF424242),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          style: GoogleFonts.montserrat(color: Colors.white),
                          items: _statusOptions.sublist(1).map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateOrderStatus(order['id'], value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Toplam Tutar',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₺${order['total'].toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.montserrat(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // PDF oluşturma ya da yazdırma özelliği eklenebilir
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yazdırma özelliği yakında eklenecek')),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print, size: 18),
                        const SizedBox(width: 8),
                        Text('Yazdır', style: GoogleFonts.montserrat()),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'tamamlandı':
        return Icons.check_circle;
      case 'beklemede':
        return Icons.schedule;
      case 'işleniyor':
        return Icons.sync;
      case 'iptal':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: Column(
        children: [
          AdminTopbar(
            title: 'Sipariş Yönetimi',
            actions: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: GoogleFonts.montserrat(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Sipariş ara...',
                    hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF424242),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _statusFilter,
                dropdownColor: const Color(0xFF424242),
                icon: const Icon(Icons.filter_list, color: Colors.white),
                underline: Container(),
                style: GoogleFonts.montserrat(color: Colors.white),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _statusFilter = value;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadOrders,
                tooltip: 'Yenile',
                color: Colors.white,
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AdminTable<Map<String, dynamic>>(
                columns: const ['Sipariş ID', 'Tarih', 'Müşteri', 'Toplam', 'Durum', 'İşlemler'],
                data: _filteredOrders,
                isLoading: _isLoading,
                onRowTap: _showOrderDetails,
                cellBuilder: (order, index) => [
                  DataCell(Text(
                    order['id'].toString().substring(0, 8),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )),
                  DataCell(Text(
                    _formatDate(order['date'].toString()),
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
                  DataCell(Text(
                    order['userName'],
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
                  DataCell(Text(
                    '₺${order['total'].toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['status'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ActionCell(
                      actions: [
                        ActionItem(
                          icon: Icons.visibility,
                          onPressed: () => _showOrderDetails(order),
                          tooltip: 'Detay',
                          color: Colors.blue,
                        ),
                        ActionItem(
                          icon: Icons.edit,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF333333),
                                title: Text(
                                  'Sipariş Durumu Güncelle',
                                  style: GoogleFonts.montserrat(color: Colors.white),
                                ),
                                content: DropdownButtonFormField<String>(
                                  value: order['status'],
                                  dropdownColor: const Color(0xFF424242),
                                  decoration: InputDecoration(
                                    labelText: 'Durum',
                                    labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                                    filled: true,
                                    fillColor: const Color(0xFF424242),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: GoogleFonts.montserrat(color: Colors.white),
                                  items: _statusOptions.sublist(1).map((status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      // Seçilen değeri sakla
                                    });
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'İptal',
                                      style: GoogleFonts.montserrat(color: Colors.grey),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _updateOrderStatus(order['id'], order['status']);
                                    },
                                    child: Text(
                                      'Güncelle',
                                      style: GoogleFonts.montserrat(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: 'Düzenle',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 