import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/admin_stock_service.dart';
import 'file_exporter_service.dart' as file_exporter;
import 'package:flutter/foundation.dart' show kIsWeb;

class StockManagement extends StatefulWidget {
  const StockManagement({super.key});

  @override
  State<StockManagement> createState() => _StockManagementState();
}

class _StockManagementState extends State<StockManagement> {
  final AdminStockService _stockService = AdminStockService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _productsStockData = [];
  List<Map<String, dynamic>> _filteredStockData = []; // For client-side filtering
  String _errorMessage = '';
  
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String? _selectedCategoryFilter;
  String? _selectedStockStatusFilter; // e.g., "low", "out", "in"

  List<String> _availableCategories = [];

  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchTerm) { // Avoid redundant calls
        setState(() {
          _searchTerm = _searchController.text;
        });
        _applyFiltersAndSort(); // Apply filters when search term changes
      }
    });
    _fetchStockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStockData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Assuming AdminStockService.fetchStockData doesn't support server-side filtering for now.
      // If it does, pass _searchTerm, _selectedCategoryFilter, _selectedStockStatusFilter
      _productsStockData = await _stockService.fetchStockData();
      _extractCategories();
      _applyFiltersAndSort(); // Apply initial filters and sort
      print('StockManagement: ${_productsStockData.length} ürün stok bilgisi servisten yüklendi.');
    } catch (e) {
      print('StockManagement: Stok verisi yükleme hatası: $e');
      _errorMessage = "Stok verisi yüklenemedi: ${e.toString()}";
      // _loadDemoStockData(); // Demo data loading can be kept if needed
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _extractCategories() {
    if (_productsStockData.isNotEmpty) {
      final categories = _productsStockData
          .map((p) => p['category']?.toString())
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      categories.sort();
      if (mounted) {
        setState(() {
          _availableCategories = categories;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> tempFilteredData = List.from(_productsStockData);

    // Apply search term filter
    if (_searchTerm.isNotEmpty) {
      tempFilteredData = tempFilteredData.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        return name.contains(_searchTerm.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'all') {
      tempFilteredData = tempFilteredData.where((product) {
        return product['category']?.toString() == _selectedCategoryFilter;
      }).toList();
    }

    // Apply stock status filter
    if (_selectedStockStatusFilter != null && _selectedStockStatusFilter != 'all') {
      tempFilteredData = tempFilteredData.where((product) {
        final stock = product['stock'] as int? ?? 0;
        final minStock = product['minStock'] as int? ?? 0;
        switch (_selectedStockStatusFilter) {
          case 'lowstock':
            return stock > 0 && stock < minStock;
          case 'outofstock':
            return stock <= 0;
          case 'instock':
            return stock > 0;
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply sorting
    tempFilteredData.sort((a, b) {
      dynamic valA = a[_sortColumn];
      dynamic valB = b[_sortColumn];

      // Handle nulls or different types if necessary
      if (valA == null && valB == null) return 0;
      if (valA == null) return _sortAscending ? -1 : 1;
      if (valB == null) return _sortAscending ? 1 : -1;
      
      int comparison;
      if (valA is String && valB is String) {
        comparison = valA.toLowerCase().compareTo(valB.toLowerCase());
      } else if (valA is num && valB is num) {
        comparison = valA.compareTo(valB);
      } else {
        comparison = valA.toString().toLowerCase().compareTo(valB.toString().toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });


    if (mounted) {
      setState(() {
        _filteredStockData = tempFilteredData;
      });
    }
  }
  
  void _loadDemoStockData() {
    // Bu fonksiyon, _fetchStockData'da hata olduğunda çağrılır.
    // _stockService.fetchStockData() web için zaten demo döndürebilir,
    // bu yüzden bu sadece son çare olmalı veya web için fetchStockData'nın demo döndürmesi yeterli.
    print('⚠️ StockManagement: Demo stok verileri yükleniyor (fetch hatası sonrası).');
    setState(() {
      _productsStockData = [
        {
          'id': 'demo1',
          'name': 'Demo Elma',
          'category': 'Meyve',
          'stock': 10,
          'minStock': 5,
          'price': 10.0,
          'lastUpdated': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _updateStock(String productId, int newStockValue, {int? minStock}) async {
    // minStock şu an serviste kullanılmıyor, ama UI'dan gelirse diye parametre olarak kalabilir.
    try {
      await _stockService.updateProductStock(productId, newStockValue);
      print('StockManagement: Stok başarıyla güncellendi.');
      await _fetchStockData(); // Listeyi yenile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok başarıyla güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('StockManagement: Stok güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok güncellenemedi: ${e.toString()}'), backgroundColor: Colors.red),
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
                    'Stok Yönetimi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportReport,
                        icon: const Icon(Icons.file_download),
                        label: kIsWeb ? const Text('Rapor') : const SizedBox.shrink(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 8, vertical: 8),
                        ),
                      ),
                      SizedBox(width: kIsWeb ? 16 : 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showStockUpdateDialog(context);
                        },
                        icon: const Icon(Icons.update),
                        label: kIsWeb ? const Text('Toplu Güncelleme') : const SizedBox.shrink(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 16 : 8, vertical: 8),
                        ),
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
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
                      : _filteredStockData.isEmpty
                          ? const Center(child: Text('Filtreye uygun ürün bulunamadı veya stok boş.', style: TextStyle(fontSize: 16)))
                          : _buildStockTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün adıyla ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16.0, // Yatay boşluk
              runSpacing: 12.0, // Dikey boşluk (alt satıra geçtiğinde)
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200), // Minimum genişlik
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    value: _selectedCategoryFilter,
                    hint: const Text('Tüm Kategoriler'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(value: 'all', child: Text('Tüm Kategoriler')),
                      ..._availableCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryFilter = value;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200), // Minimum genişlik
                  child: DropdownButtonFormField<String>(
                     decoration: InputDecoration(
                      labelText: 'Stok Durumu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    value: _selectedStockStatusFilter,
                    hint: const Text('Tüm Durumlar'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tüm Durumlar')),
                      DropdownMenuItem(value: 'instock', child: Text('Stokta Var')),
                      DropdownMenuItem(value: 'lowstock', child: Text('Düşük Stok')),
                      DropdownMenuItem(value: 'outofstock', child: Text('Stokta Yok')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStockStatusFilter = value;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSummary() {
    // Stok özeti için hesaplamalar _filteredStockData üzerinden yapılmalı
    final totalProducts = _filteredStockData.length;
    final lowStockCount = _filteredStockData.where((p) {
      final stock = p['stock'] as int? ?? 0;
      final minStock = p['minStock'] as int? ?? 0;
      return stock > 0 && stock < minStock;
    }).length;
    final outOfStockCount = _filteredStockData.where((p) => (p['stock'] as int? ?? 0) <= 0).length;
    
    // Mobil için kartların minimum genişliğini biraz daha küçük ayarlayabiliriz.
    final double cardMinWidth = kIsWeb ? 220 : 160; 

    return Wrap(
      spacing: 16.0, // Kartlar arası yatay boşluk
      runSpacing: 16.0, // Kartlar alt satıra geçtiğinde dikey boşluk
      alignment: kIsWeb ? WrapAlignment.start : WrapAlignment.center, // Mobil için ortalayabiliriz
      children: [
        _buildStockSummaryCard('Toplam Filtrelenmiş Ürün', totalProducts.toString(), Colors.blue, minWidth: cardMinWidth),
        _buildStockSummaryCard('Düşük Stok (Filtrelenmiş)', lowStockCount.toString(), Colors.orange, minWidth: cardMinWidth),
        _buildStockSummaryCard('Stokta Yok (Filtrelenmiş)', outOfStockCount.toString(), Colors.red, minWidth: cardMinWidth),
      ],
    );
  }

  Widget _buildStockSummaryCard(String title, String value, Color color, {double minWidth = 150}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth), // Dinamik minimum genişlik
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
    if (_filteredStockData.isEmpty && _errorMessage.isEmpty && !_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Filtreye uygun ürün bulunamadı.', style: TextStyle(fontSize: 16))));
    }
    if (_errorMessage.isNotEmpty && !_isLoading) {
       return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16))));
    }

    const List<DataColumn> columns = [
        DataColumn(label: Text('Ürün Adı'), numeric: false, tooltip: 'Ürünün adı'),
        DataColumn(label: Text('Kategori'), numeric: false, tooltip: 'Ürünün kategorisi'),
        DataColumn(label: Text('Stok'), numeric: true, tooltip: 'Mevcut stok adedi'),
        DataColumn(label: Text('Min. Stok'), numeric: true, tooltip: 'Minimum stok seviyesi'),
        DataColumn(label: Text('Güncellenme'), numeric: false, tooltip: 'Son stok güncelleme tarihi'),
        DataColumn(label: Text('İşlemler'), numeric: false, tooltip: 'Stok düzenleme işlemleri'),
    ];
    
    // Sorting logic will be applied in _applyFiltersAndSort
    // DataTable columns need to be dynamic if we want to show sort indicators

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView( // For horizontal scroll if table is too wide
        scrollDirection: Axis.horizontal,
        child: DataTable(
            sortColumnIndex: (){
              if (columns.isEmpty) return null;
              int index = columns.indexWhere((col) {
                if (col.label is Text) {
                  final labelText = (col.label as Text).data?.toLowerCase().replaceAll(' ', '').replaceAll('.', '') ?? '';
                  final sortColumnText = _sortColumn.toLowerCase().replaceAll('ürün ', '').replaceAll('min. ', '').replaceAll(' ', '');
                  return labelText.startsWith(sortColumnText);
                }
                return false;
              });
              return index == -1 ? null : index;
            }(),
            sortAscending: _sortAscending,
            columnSpacing: kIsWeb ? 20 : 10, // Mobil için sütun aralığı azaltıldı
            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey.shade50),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            columns: columns.map((col) {
              String colLabel = (col.label as Text).data!;
              String colId = colLabel.toLowerCase().replaceAll('ürün ', '').replaceAll('min. ', '').replaceAll('.', '').replaceAll(' ', '');
              if (colId == "güncellenme") colId = "lastUpdated"; // map to data field

              return DataColumn(
                label: Text(colLabel),
                numeric: col.numeric,
                tooltip: col.tooltip,
                onSort: (columnIndex, ascending) {
                    setState(() {
                        _sortColumn = colId;
                        _sortAscending = ascending;
                    });
                    _applyFiltersAndSort();
                }
              );
            }).toList(),
            rows: _filteredStockData.map((product) { // Use _filteredStockData
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                    final stock = product['stock'] as int? ?? 0;
                    final minStock = product['minStock'] as int? ?? 0;
                    if (stock <= 0) return Colors.red.withOpacity(0.05);
                    if (stock < minStock) return Colors.orange.withOpacity(0.05);
                    return null; // Default
                }),
                cells: [
                DataCell(Text(product['name']?.toString() ?? 'N/A')),
                DataCell(Text(product['category']?.toString() ?? 'N/A')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStockStatusColor(product),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(product['stock']?.toString() ?? '0'),
                    ],
                  ),
                ),
                DataCell(Text(product['minStock']?.toString() ?? '0')),
                DataCell(Text(product['lastUpdated']?.toString() ?? '-')), // Assuming lastUpdated is a string
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: "Stok Ekle",
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                        onPressed: () {
                          _showAddStockDialog(context, product);
                        },
                      ),
                    ),
                    Tooltip(
                      message: "Stok Düzenle",
                      child: IconButton(
                        icon: const Icon(Icons.edit_note, size: 20, color: Colors.blueAccent),
                        onPressed: () {
                          _showEditStockDialog(context, product);
                        },
                      ),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
    );
  }

  Color _getStockStatusColor(Map<String, dynamic> product) {
    final stock = product['stock'] as int? ?? 0;
    final minStock = product['minStock'] as int? ?? 0;
    
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
                  
                  final newStock = (product['stock'] as int) + quantity;
                  
                  _updateStock(
                    product['id'].toString(),
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
                
                _updateStock(
                  product['id'].toString(),
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

  void _showStockUpdateDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final _formKey = GlobalKey<FormState>();
    String? _selectedProductId = product?['id']?.toString(); // product id'sini string'e çevir
    final _stockController = TextEditingController(text: product?['stock']?.toString() ?? '');
    final _minStockController = TextEditingController(text: product?['minStock']?.toString() ?? '5'); // Varsayılan min stok

    // Eğer product null ise (Toplu Güncelleme), ürün seçimi için bir dropdown göster
    // product doluysa (Tekli Güncelleme), o ürünün adı gösterilir.

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product == null ? 'Toplu Stok Güncelle' : 'Stok Güncelle: ${product['name']}'),
          content: StatefulBuilder( // Dropdown'ın güncellenmesi için StatefulBuilder
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (product == null) // Sadece toplu güncellemede ürün seçimi göster
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Ürün Seçin'),
                        value: _selectedProductId,
                        hint: const Text('Güncellenecek ürünü seçin'),
                        items: _productsStockData // _products yerine _productsStockData kullanıldı
                            .map((p) => DropdownMenuItem<String>(
                                  value: p['id'] as String?,
                                  child: Text(p['name'] as String? ?? 'İsimsiz Ürün'),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedProductId = newValue;
                            // Seçilen ürünün mevcut stok ve minStok değerlerini göstermek için:
                            if (newValue != null) {
                              final selectedProductData = _productsStockData.firstWhere((p) => p['id'] == newValue); // _products yerine _productsStockData kullanıldı
                              _stockController.text = selectedProductData['stock']?.toString() ?? '';
                              _minStockController.text = selectedProductData['minStock']?.toString() ?? '5';
                            }
                          });
                        },
                        validator: (value) => value == null ? 'Lütfen bir ürün seçin' : null,
                      ),
                    if (product != null) // Tekli güncellemede ürün adını göster
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Ürün: ${product['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    TextField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Yeni Stok Miktarı'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _minStockController,
                      decoration: const InputDecoration(labelText: 'Yeni Minimum Stok Miktarı'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              );
            },
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
                if (_formKey.currentState!.validate()) {
                  final newStock = int.tryParse(_stockController.text) ?? 0;
                  final newMinStock = int.tryParse(_minStockController.text) ?? 0;
                  
                  Navigator.of(context).pop();
                  
                  // API ile güncelle
                  if (_selectedProductId != null) { // _selectedProductId null değilse güncelle
                    _updateStock(_selectedProductId!, newStock, minStock: newMinStock);
                  } else {
                    // Kullanıcıya bir ürün seçmesi gerektiği konusunda uyarı gösterilebilir.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen bir ürün seçin.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _exportReport() {
    if (_filteredStockData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak veri bulunmuyor.')),
      );
      return;
    }

    // CSV Başlıkları
    List<String> headers = [
      'ID', 'Ürün Adı', 'Kategori', 'Stok Miktarı', 
      'Min. Stok', 'Fiyat', 'Son Güncelleme' 
      // İhtiyaç duyulan diğer başlıklar eklenebilir
    ];
    String csvData = "${headers.join(',')}\\n";

    // CSV Satırları
    for (var product in _filteredStockData) {
      List<String> row = [
        product['id']?.toString() ?? 'N/A',
        '"${product['name']?.toString().replaceAll('"', '""') ?? 'N/A'}"', // Çift tırnakları escape et
        product['category']?.toString() ?? 'N/A',
        product['stock']?.toString() ?? '0',
        product['minStock']?.toString() ?? '0',
        product['price']?.toString() ?? '0.0',
        product['lastUpdated']?.toString() ?? 'N/A',
        // Diğer alanlar
      ];
      csvData += "${row.join(',')}\\n";
    }

    if (kIsWeb) {
      // WEB PLATFORMU İÇİN İNDİRME
      try {
        file_exporter.exportCsvWeb(csvData, 'stok_raporu');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor başarıyla indirildi.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        print("Web CSV indirme hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor indirilemedi (Web): ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } else {
      // MOBİL PLATFORMLAR İÇİN
      print('--- STOK RAPORU (CSV) ---');
      print(csvData);
      print('--- RAPOR SONU ---');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor oluşturuldu ve konsola yazdırıldı. Mobil kaydetme için ek geliştirme gerekir.')),
      );
    }
  }
} 
