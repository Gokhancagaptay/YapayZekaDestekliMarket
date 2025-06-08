import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // API URL'ini platforma göre belirle
      final url = kIsWeb
          ? 'http://localhost:8000/api/products'
          : 'http://10.0.2.2:8000/api/products';
      
      print('MongoDB API\'den ürünler yükleniyor: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('MongoDB API cevabı: ${jsonData.toString().substring(0, 100)}...');
        
        if (jsonData['products'] != null) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(jsonData['products']);
            _isLoading = false;
          });
          print('✅ ${_products.length} adet ürün MongoDB\'den başarıyla yüklendi');
        } else {
          setState(() {
            _products = [];
            _isLoading = false;
          });
          print('ℹ️ MongoDB\'den yüklenen ürün yok');
        }
      } else {
        setState(() {
          _errorMessage = 'MongoDB API hatası: ${response.statusCode}';
          _isLoading = false;
        });
        print('❌ MongoDB API hatası: ${response.statusCode}');
        
        // Demo verileri yükle
        _loadDemoProducts();
      }
    } catch (e) {
      print('❌ MongoDB bağlantı hatası: $e');
      setState(() {
        _errorMessage = 'MongoDB bağlantı hatası: $e';
        _isLoading = false;
      });
      
      // Demo verileri yükle
      _loadDemoProducts();
    }
  }
  
  void _loadDemoProducts() {
    print('⚠️ Demo ürün verileri yükleniyor');
    setState(() {
      _products = [
        {
          '_id': '1',
          'name': 'Elma',
          'price': 9.99,
          'stock': 100,
          'category': 'Meyve',
        },
        {
          '_id': '2',
          'name': 'Domates',
          'price': 7.50,
          'stock': 85,
          'category': 'Sebze',
        },
        {
          '_id': '3',
          'name': 'Süt',
          'price': 12.25,
          'stock': 50,
          'category': 'Süt Ürünleri',
        },
        {
          '_id': '4',
          'name': 'Yumurta',
          'price': 24.99,
          'stock': 120,
          'category': 'Kahvaltılık',
        },
        {
          '_id': '5',
          'name': 'Ekmek',
          'price': 5.00,
          'stock': 75,
          'category': 'Fırın',
        },
      ];
    });
  }
  
  // Yeni ürün eklemek için MongoDB API'sine istek gönderen fonksiyon
  Future<void> _addProduct(Map<String, dynamic> product) async {
    try {
      final url = kIsWeb
          ? 'http://localhost:8000/api/products'
          : 'http://10.0.2.2:8000/api/products';
      
      print('🔄 Ürün ekleniyor: ${product['name']}');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Ürün başarıyla MongoDB\'ye eklendi');
        _fetchProducts(); // Ürünleri yenile
      } else {
        print('❌ Ürün eklenirken MongoDB API hatası: ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ürün eklenirken hata: $e');
      // Sadece yerel state'i güncelle
      setState(() {
        product['_id'] = DateTime.now().millisecondsSinceEpoch.toString();
        _products.add(product);
      });
    }
  }
  
  // Ürün güncellemek için MongoDB API'sine istek gönderen fonksiyon
  Future<void> _updateProduct(String id, Map<String, dynamic> updatedProduct) async {
    try {
      final url = kIsWeb
          ? 'http://localhost:8000/api/products/$id'
          : 'http://10.0.2.2:8000/api/products/$id';
      
      print('🔄 Ürün güncelleniyor: $id');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedProduct),
      );
      
      if (response.statusCode == 200) {
        print('✅ Ürün başarıyla MongoDB\'de güncellendi');
        _fetchProducts(); // Ürünleri yenile
      } else {
        print('❌ Ürün güncellenirken MongoDB API hatası: ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ürün güncellenirken hata: $e');
      // Sadece yerel state'i güncelle
      setState(() {
        final index = _products.indexWhere((p) => p['_id'].toString() == id);
        if (index != -1) {
          _products[index] = {...updatedProduct, '_id': id};
        }
      });
    }
  }
  
  // Ürün silmek için MongoDB API'sine istek gönderen fonksiyon
  Future<void> _deleteProduct(String id) async {
    try {
      final url = kIsWeb
          ? 'http://localhost:8000/api/products/$id'
          : 'http://10.0.2.2:8000/api/products/$id';
      
      print('🔄 Ürün siliniyor: $id');
      final response = await http.delete(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('✅ Ürün başarıyla MongoDB\'den silindi');
        _fetchProducts(); // Ürünleri yenile
      } else {
        print('❌ Ürün silinirken MongoDB API hatası: ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        throw Exception('API hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ürün silinirken hata: $e');
      // Sadece yerel state'i güncelle
      setState(() {
        _products.removeWhere((p) => p['_id'].toString() == id);
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
                  'Ürün Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddProductDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Ürün'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchProducts,
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Center(child: Text('Ürün bulunamadı'))
                      : _buildProductsTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
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
            DropdownMenuItem(value: 'meyve', child: Text('Meyve')),
            DropdownMenuItem(value: 'sebze', child: Text('Sebze')),
            DropdownMenuItem(value: 'sut', child: Text('Süt Ürünleri')),
          ],
          onChanged: (value) {
            // Kategori filtresi
          },
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Ürün Adı')),
              DataColumn(label: Text('Fiyat (₺)')),
              DataColumn(label: Text('Stok')),
              DataColumn(label: Text('Kategori')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: _products.map((product) {
              return DataRow(cells: [
                DataCell(Text(product['name'].toString())),
                DataCell(
                  Text(
                    NumberFormat.currency(
                      locale: 'tr',
                      symbol: '',
                      decimalDigits: 2,
                    ).format(product['price']),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStockStatusColor(product['stock']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(product['stock'].toString()),
                    ],
                  ),
                ),
                DataCell(Text(product['category'].toString())),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showEditProductDialog(context, product);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        _showDeleteProductDialog(context, product);
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

  Color _getStockStatusColor(dynamic stock) {
    final stockValue = stock is int ? stock : int.tryParse(stock.toString()) ?? 0;
    if (stockValue <= 0) {
      return Colors.red;
    } else if (stockValue <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = 'Meyve';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Ürün Ekle'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ürün Adı'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stok Miktarı'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const [
                    DropdownMenuItem(value: 'Meyve', child: Text('Meyve')),
                    DropdownMenuItem(value: 'Sebze', child: Text('Sebze')),
                    DropdownMenuItem(value: 'Süt Ürünleri', child: Text('Süt Ürünleri')),
                    DropdownMenuItem(value: 'Kahvaltılık', child: Text('Kahvaltılık')),
                    DropdownMenuItem(value: 'Fırın', child: Text('Fırın')),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ekle'),
              onPressed: () {
                // Ürün ekleme işlemi
                final newProduct = {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'category': selectedCategory,
                };
                
                Navigator.of(context).pop();
                _addProduct(newProduct);
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name'].toString());
    final priceController = TextEditingController(text: product['price'].toString());
    final stockController = TextEditingController(text: product['stock'].toString());
    String selectedCategory = product['category'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ürün Düzenle'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ürün Adı'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stok Miktarı'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: const [
                    DropdownMenuItem(value: 'Meyve', child: Text('Meyve')),
                    DropdownMenuItem(value: 'Sebze', child: Text('Sebze')),
                    DropdownMenuItem(value: 'Süt Ürünleri', child: Text('Süt Ürünleri')),
                    DropdownMenuItem(value: 'Kahvaltılık', child: Text('Kahvaltılık')),
                    DropdownMenuItem(value: 'Fırın', child: Text('Fırın')),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                // Ürün güncelleme işlemi
                final updatedProduct = {
                  'name': nameController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'category': selectedCategory,
                };
                
                Navigator.of(context).pop();
                _updateProduct(product['_id'], updatedProduct);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProductDialog(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ürün Sil'),
          content: Text(
            '${product['name']} ürününü silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product['_id']);
              },
            ),
          ],
        );
      },
    );
  }
} 