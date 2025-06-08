import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class StockManagement extends StatefulWidget {
  const StockManagement({super.key});

  @override
  State<StockManagement> createState() => _StockManagementState();
}

class _StockManagementState extends State<StockManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }

  void _loadDemoData() {
    setState(() {
      _isLoading = true;
    });
    
    _fetchProductsFromApi();
  }
  
  Future<void> _fetchProductsFromApi() async {
    try {
      // API URL'ini platforma göre belirle
      final url = kIsWeb
          ? 'http://localhost:8000/api/products'
          : 'http://10.0.2.2:8000/api/products';
      
      print('🔄 MongoDB API\'den stok bilgisi yükleniyor: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ MongoDB API cevabı alındı');
        
        // API'nin döndürdüğü yapı değişmiş olabilir, iki formatı da kontrol edelim
        List<dynamic> products;
        
        if (jsonData is List) {
          // API doğrudan ürün listesi döndürüyor
          products = jsonData;
          print('✅ API direkt liste döndürüyor');
        } else if (jsonData is Map && jsonData['products'] != null) {
          // API {'products': [...]} formatında döndürüyor
          products = jsonData['products'];
          print('✅ API products anahtarı ile döndürüyor');
        } else {
          print('⚠️ MongoDB\'den beklenmeyen veri formatı - demo veri kullanılıyor');
          _loadDemoProducts();
          return;
        }
          
        setState(() {
          _products = products.map((product) => {
            // MongoDB bazen _id, bazen id kullanabilir
            'id': product['_id'] ?? product['id'] ?? '',
            'name': product['name'] ?? 'İsimsiz Ürün',
            'category': product['category'] ?? 'Diğer',
            'stock': product['stock'] ?? 0,
            'minStock': product['minStock'] ?? 10, // API'de yoksa varsayılan değer
            'price': product['price'] ?? 0.0,
            'lastUpdated': product['updatedAt'] != null 
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(product['updatedAt']))
                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          }).toList().cast<Map<String, dynamic>>();
          
          _isLoading = false;
        });
        
        print('✅ ${_products.length} adet ürün stok bilgisi MongoDB\'den yüklendi');
      } else {
        print('❌ MongoDB API hatası: ${response.statusCode}');
        _loadDemoProducts();
      }
    } catch (e) {
      print('❌ MongoDB bağlantı hatası: $e');
      _loadDemoProducts();
    }
  }
  
  void _loadDemoProducts() {
    print('⚠️ Demo stok verileri yükleniyor');
    setState(() {
      _products = [
        {
          'id': '1',
          'name': 'Elma',
          'category': 'Meyve',
          'stock': 32,
          'minStock': 10,
          'price': 9.99,
          'lastUpdated': '2023-10-15',
        },
        {
          'id': '2',
          'name': 'Domates',
          'category': 'Sebze',
          'stock': 8,
          'minStock': 15,
          'price': 7.50,
          'lastUpdated': '2023-10-16',
        },
        {
          'id': '3',
          'name': 'Süt',
          'category': 'Süt Ürünleri',
          'stock': 5,
          'minStock': 20,
          'price': 12.25,
          'lastUpdated': '2023-10-17',
        },
        {
          'id': '4',
          'name': 'Yumurta',
          'category': 'Kahvaltılık',
          'stock': 120,
          'minStock': 30,
          'price': 24.99,
          'lastUpdated': '2023-10-15',
        },
        {
          'id': '5',
          'name': 'Ekmek',
          'category': 'Fırın',
          'stock': 0,
          'minStock': 15,
          'price': 5.00,
          'lastUpdated': '2023-10-17',
        },
      ];
      _isLoading = false;
    });
  }
  
  // Stok güncellemek için MongoDB API'sine istek gönderen fonksiyon
  Future<void> _updateStock(String id, int newStockValue, {int? minStock}) async {
    try {
      // Backend PUT metodunu kullanıyor, PATCH değil
      final url = kIsWeb
          ? 'http://localhost:8000/api/products/$id'
          : 'http://10.0.2.2:8000/api/products/$id';
      
      print('🔄 Ürün stoğu güncelleniyor: $id, yeni stok: $newStockValue');
      
      // Backend name parametresiyle çalışıyor, id değil
      // Ayrıca backend sadece stock ve price alanlarını güncelliyor
      Map<String, dynamic> queryParams = {
        'stock': newStockValue.toString(),
      };
      
      // minStock backend tarafından desteklenmediği için yorum satırına aldım
      // if (minStock != null) {
      //   queryParams['minStock'] = minStock.toString();
      // }
      
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(queryParams),
      );
      
      if (response.statusCode == 200) {
        print('✅ Ürün stoğu MongoDB\'de güncellendi');
        await _fetchProductsFromApi(); // Güncel verileri yükle
      } else {
        print('❌ Stok güncellenirken MongoDB API hatası: ${response.statusCode}');
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Stok güncellenirken hata: $e');
      // Sadece yerel state'i güncelle
      setState(() {
        final index = _products.indexWhere((p) => p['id'] == id);
        if (index != -1) {
          _products[index]['stock'] = newStockValue;
          if (minStock != null) {
            _products[index]['minStock'] = minStock;
          }
          _products[index]['lastUpdated'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }
      });
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
                  'Stok Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Stok raporunu dışa aktar
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Rapor'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showStockUpdateDialog(context);
                      },
                      icon: const Icon(Icons.update),
                      label: const Text('Toplu Güncelleme'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildStockSummary(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStockTable(),
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
              hintText: 'Ürün ara...',
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
          hint: const Text('Kategori'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tümü')),
            DropdownMenuItem(value: 'lowstock', child: Text('Düşük Stok')),
            DropdownMenuItem(value: 'outofstock', child: Text('Stokta Yok')),
            DropdownMenuItem(value: 'instock', child: Text('Stokta Var')),
          ],
          onChanged: (value) {
            // Filtreleme işlemi
          },
        ),
      ],
    );
  }

  Widget _buildStockSummary() {
    // Stok özeti için hesaplamalar
    final totalProducts = _products.length;
    final lowStockCount = _products.where((p) => p['stock'] < p['minStock'] && p['stock'] > 0).length;
    final outOfStockCount = _products.where((p) => p['stock'] <= 0).length;
    
    return Row(
      children: [
        _buildStockSummaryCard(
          'Toplam Ürün',
          totalProducts.toString(),
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStockSummaryCard(
          'Düşük Stok',
          lowStockCount.toString(),
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStockSummaryCard(
          'Stokta Yok',
          outOfStockCount.toString(),
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStockSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStockTable() {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Ürün Adı')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('Stok')),
              DataColumn(label: Text('Min. Stok')),
              DataColumn(label: Text('Güncellenme')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: _products.map((product) {
              return DataRow(cells: [
                DataCell(Text(product['name'].toString())),
                DataCell(Text(product['category'].toString())),
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStockStatusColor(product),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(product['stock'].toString()),
                    ],
                  ),
                ),
                DataCell(Text(product['minStock'].toString())),
                DataCell(Text(product['lastUpdated'])),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () {
                        _showAddStockDialog(context, product);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showEditStockDialog(context, product);
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

  Color _getStockStatusColor(Map<String, dynamic> product) {
    final stock = product['stock'] as int;
    final minStock = product['minStock'] as int;
    
    if (stock <= 0) {
      return Colors.red;
    } else if (stock < minStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showAddStockDialog(BuildContext context, Map<String, dynamic> product) {
    final quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${product['name']} - Stok Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mevcut Stok: ${product['stock']}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Eklenecek Miktar'),
                keyboardType: TextInputType.number,
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
              onPressed: () {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity > 0) {
                  Navigator.of(context).pop();
                  
                  // Yeni stok miktarı hesapla
                  final newStock = (product['stock'] as int) + quantity;
                  
                  // API ile güncelle
                  _updateStock(
                    product['name'].toString(), // Backend id yerine name bekliyor
                    newStock,
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showEditStockDialog(BuildContext context, Map<String, dynamic> product) {
    final stockController = TextEditingController(text: product['stock'].toString());
    final minStockController = TextEditingController(text: product['minStock'].toString());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${product['name']} - Stok Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stok Miktarı'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minStockController,
                decoration: const InputDecoration(labelText: 'Minimum Stok Miktarı'),
                keyboardType: TextInputType.number,
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
              onPressed: () {
                final stock = int.tryParse(stockController.text) ?? 0;
                final minStock = int.tryParse(minStockController.text) ?? 0;
                
                Navigator.of(context).pop();
                
                // API ile güncelle - Backend şu an minStock'u desteklemiyor 
                // ancak yerel state içinde saklıyoruz
                _updateStock(
                  product['name'].toString(), // Backend id yerine name bekliyor
                  stock,
                  minStock: minStock
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _showStockUpdateDialog(BuildContext context) {
    final selectedProduct = ValueNotifier<String?>('');
    final quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Toplu Stok Güncelleme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Ürün'),
                items: _products
                    .map((p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text('${p['name']} (Stok: ${p['stock']})'),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedProduct.value = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Yeni Stok Miktarı'),
                keyboardType: TextInputType.number,
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
              onPressed: () {
                if (selectedProduct.value != null && selectedProduct.value!.isNotEmpty) {
                  final quantity = int.tryParse(quantityController.text) ?? 0;
                  
                  Navigator.of(context).pop();
                  
                  // Seçilen ürünün adını bul (backend id yerine name bekliyor)
                  final selectedProductData = _products.firstWhere(
                    (p) => p['id'].toString() == selectedProduct.value,
                    orElse: () => {'name': selectedProduct.value}
                  );
                  
                  // API ile güncelle
                  _updateStock(selectedProductData['name'].toString(), quantity);
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