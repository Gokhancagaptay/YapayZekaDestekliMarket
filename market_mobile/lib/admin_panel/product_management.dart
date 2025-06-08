import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter için
// import 'dart:convert'; // Artık doğrudan kullanılmıyor gibi
import 'package:intl/intl.dart'; // Fiyat formatlama için
import 'services/admin_product_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final AdminProductService _productService = AdminProductService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String _errorMessage = '';

  String _searchTerm = '';
  String? _selectedCategory;
  List<String> _categories = []; // API'den yüklenecek

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _fetchCategories(); // Önce kategorileri çek
      await _fetchProducts();   // Sonra ürünleri (filtresiz başlangıçta)
    } catch (e) {
      // _fetchCategories veya _fetchProducts kendi içinde hata yönetimi yapacak
      // ve _errorMessage'i set edecek. Burada genel bir setState yeterli.
      print("Initialization error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    // Bu fonksiyon isLoading'i doğrudan set etmez, _initializePage veya refresh içinde yönetilir.
    try {
      _categories = await _productService.fetchCategories();
      print('ProductManagement: ${_categories.length} kategori servisten yüklendi.');
      if (mounted) {
        setState(() {}); // Kategoriler güncellendi, UI'ı yenile (Dropdown için)
      }
    } catch (e) {
      print('ProductManagement: Kategori yükleme hatası: $e');
      if (mounted) {
      setState(() {
          _errorMessage = "Kategoriler yüklenirken bir hata oluştu: ${e.toString()}";
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _fetchProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
    setState(() {
        _isLoading = true;
        _errorMessage = '';
    });
  }
    try {
      _products = await _productService.fetchProducts(
        searchTerm: _searchTerm,
        category: _selectedCategory,
      );
      print('ProductManagement: ${_products.length} ürün servisten yüklendi (Arama: $_searchTerm, Kategori: $_selectedCategory).');
    } catch (e) {
      print('ProductManagement: Ürün yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Ürünler yüklenirken bir hata oluştu: ${e.toString()}";
          _products = []; // Hata durumunda ürün listesini boşalt
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (showLoading && mounted) {
      setState(() {
          _isLoading = false;
        });
      } else if (mounted) { // showLoading false ise sadece ürün listesini güncelle
        setState(() {});
      }
    }
  }
  
  // _extractCategories kaldırıldı.
  // _loadDemoProducts kaldırıldı.

  Future<void> _addProduct(Map<String, dynamic> productData) async {
    // productData'nın price ve stock alanlarının doğru tipte (double, int) olduğundan emin ol
    // Dialog içinde bu dönüşümler yapılmalı.
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _productService.addProduct(productData);
      print('ProductManagement: Ürün başarıyla eklendi.');
      Navigator.of(context).pop(); // Dialog'u kapat
      await _fetchProducts(showLoading: false); // Arka planda listeyi yenile
      await _fetchCategories(); // Kategoriler de değişmiş olabilir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün başarıyla eklendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('ProductManagement: Ürün ekleme hatası: $e');
      if (mounted) {
        // Navigator.of(context).pop(); // Hata durumunda dialogu açık tutmak daha iyi olabilir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün eklenemedi: ${e.toString()}'), backgroundColor: Colors.red),
        );
    }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProduct(String productId, Map<String, dynamic> updatedProductData) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _productService.updateProduct(productId, updatedProductData);
      print('ProductManagement: Ürün başarıyla güncellendi.');
      Navigator.of(context).pop(); // Dialog'u kapat
      await _fetchProducts(showLoading: false); // Arka planda listeyi yenile
      await _fetchCategories(); // Kategoriler de değişmiş olabilir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün başarıyla güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('ProductManagement: Ürün güncelleme hatası: $e');
      if (mounted) {
        // Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ürün güncellenemedi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final productToDelete = _products.firstWhere((p) => p['id'] == productId, orElse: () => {});
    final productName = productToDelete['name'] ?? 'Bilinmeyen Ürün';

    if (!mounted) return;
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ürünü Sil'),
          content: Text('$productName adlı ürünü kalıcı olarak silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(child: const Text('İptal'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await _productService.deleteProduct(productId);
        print('ProductManagement: Ürün başarıyla silindi.');
        await _fetchProducts(showLoading: false); // Arka planda listeyi yenile
        // Kategorileri silme sonrası tekrar çekmeye gerek yok, ürün silinince kategori silinmez.
        // await _fetchCategories(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$productName ürünü başarıyla silindi'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('ProductManagement: Ürün silme hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ürün silinemedi: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditProductDialog({Map<String, dynamic>? product}) {
    final bool isEditing = product != null;
    final String dialogTitle = isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle';
    String productId = '';
    if (isEditing && product != null) {
      Object? idValue = product['id'];
      if (idValue != null) {
        productId = idValue.toString();
      } else {
        // id null ise, kullanıcıya hata gösterip işlemi durdurabiliriz.
        print("HATA: Düzenlenecek ürünün ID'si bulunamadı!");
        // Opsiyonel: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ürün ID'si alınamadı!")));
        return; // Dialog açılmasını engelle
      }
    }

    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(text: isEditing ? product!['name'] as String? : '');
    final TextEditingController priceController = TextEditingController(text: isEditing ? (product!['price'] as num?)?.toString() : '');
    final TextEditingController stockController = TextEditingController(text: isEditing ? (product!['stock'] as num?)?.toString() : '');
    final TextEditingController imageUrlController = TextEditingController(text: isEditing ? product!['image_url'] as String? : '');
    String? selectedDialogCategory = isEditing ? product!['category'] as String? : (_categories.isNotEmpty ? _categories.first : null);

    // Eğer düzenleme modunda ve ürünün kategorisi mevcut kategoriler listesinde yoksa,
    // ve _categories boş değilse, selectedDialogCategory'yi _categories.first olarak ayarla.
    // Bu, nadir bir durum olmalı (örn: ürünün kategorisi silinmiş ama üründe kalmış).
    // Veya daha iyisi, ürünün mevcut kategorisini dialogdaki dropdown'a ekleyebiliriz.
    // Şimdilik, eğer kategori listede yoksa ilkini seçsin veya null kalsın.
    if (isEditing && product!['category'] != null && !_categories.contains(product['category'] as String) && _categories.isNotEmpty) {
       // selectedDialogCategory = _categories.first; // Veya null bırakıp kullanıcı seçsin
    }


    showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayınca kapanmasın
      builder: (BuildContext context) {
        return StatefulBuilder( // Dialog içindeki state değişiklikleri için (örn: kategori dropdown)
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(dialogTitle),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Ürün Adı', hintText: 'Örn: Elma'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Ürün adı boş olamaz' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Fiyat (₺)', hintText: 'Örn: 9.99'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Fiyat boş olamaz';
                          if (double.tryParse(value) == null) return 'Geçerli bir fiyat girin';
                          if (double.parse(value) <= 0) return 'Fiyat 0\'dan büyük olmalı';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'Stok Adedi', hintText: 'Örn: 100'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Stok boş olamaz';
                          if (int.tryParse(value) == null) return 'Geçerli bir stok adedi girin';
                          if (int.parse(value) < 0) return 'Stok 0\'dan küçük olamaz';
                          return null;
                        },
                      ),
                       DropdownButtonFormField<String>(
                        value: selectedDialogCategory,
                        hint: const Text('Kategori Seçin'),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() { // Dialog state'ini güncellemek önemli
                            selectedDialogCategory = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Kategori seçimi zorunludur' : null,
                      ),
                      TextFormField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(labelText: 'Resim URL', hintText: 'https://example.com/image.jpg'),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Resim URL boş olamaz';
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.hasAbsolutePath) {
                            return 'Geçerli bir URL girin';
                          }
                          return null;
                        },
                      ),
                      // Resim önizleme (opsiyonel)
                      if (imageUrlController.text.isNotEmpty && Uri.tryParse(imageUrlController.text)?.hasAbsolutePath == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Image.network(
                            imageUrlController.text,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text('Resim yüklenemedi', style: TextStyle(color: Colors.orange)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(isEditing ? 'Güncelle' : 'Ekle'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final productData = {
                        'name': nameController.text,
                        'price': double.parse(priceController.text),
                        'stock': int.parse(stockController.text),
                        'image_url': imageUrlController.text,
                        'category': selectedDialogCategory!,
                      };
                      if (isEditing) {
                        _updateProduct(productId, productData);
                      } else {
                        _addProduct(productData);
    }
  }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Ürün Yönetimi')), // İsteğe bağlı
      body: SingleChildScrollView( // Added SingleChildScrollView
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ürün Yönetimi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Yenile'),
                      onPressed: () => _initializePage(), // Her şeyi yeniden yükle
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Yeni Ürün'),
                      onPressed: () => _showAddEditProductDialog(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Theme.of(context).primaryColor, // Tema rengi
                        foregroundColor: Colors.white, // Tema rengi
                      ),
                    ),
                  ],
                )
              ],
              ),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
            else if (_errorMessage.isNotEmpty && _products.isEmpty) // Hata varsa ve ürün yoksa göster
              Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16))))
            else if (_products.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Gösterilecek ürün bulunamadı.', style: TextStyle(fontSize: 16))))
            else
              _buildProductList(),
          ],
        ),
      ), // Closed SingleChildScrollView
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0), // Dikey padding artırıldı
        child: Wrap( // Row yerine Wrap kullanıldı
          spacing: 16.0, // Yatay boşluk
          runSpacing: 12.0, // Dikey boşluk (alt satıra geçtiğinde)
          alignment: WrapAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: kIsWeb ? 400 : double.infinity), // Arama çubuğu için mobil & web esnek genişlik
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ürün adıyla ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none, // veya OutlineInputBorder
                  isDense: true,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchTerm = '';
                            });
                            _fetchProducts();
                          },
                        )
                      : null,
                ),
                onSubmitted: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                  _fetchProducts();
                },
              ),
            ),
            // const SizedBox(width: 16), // Wrap içinde gereksiz
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: kIsWeb ? 300 : double.infinity), // Kategori dropdown için mobil & web esnek genişlik
              child: DropdownButtonFormField<String>(
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                value: _selectedCategory,
                hint: const Text('Tüm Kategoriler'),
                isExpanded: true, // ConstrainedBox ile kullanıldığında isExpanded true olabilir
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tüm Kategoriler'),
                  ),
                  ..._categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _fetchProducts();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Geniş tablolar için yatay kaydırma
          child: DataTable(
            columnSpacing: kIsWeb ? 20 : 10, // Mobil için sütun aralığı azaltıldı
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey.shade50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
            columns: const [
            DataColumn(label: Text('Resim')),
              DataColumn(label: Text('Ürün Adı')),
            DataColumn(label: Text('Kategori')),
            DataColumn(label: Text('Fiyat')),
              DataColumn(label: Text('Stok')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: _products.map((product) {
            return DataRow(
              cells: [
                DataCell(
                  (product['image_url'] != null && (product['image_url'] as String).isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Image.network(
                            product['image_url'] as String,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2,)));
                            },
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
                DataCell(Text(product['name'] as String? ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(product['category'] as String? ?? 'N/A')),
                DataCell(Text(currencyFormatter.format(product['price'] as num? ?? 0.0))),
                DataCell(Text((product['stock'] as num? ?? 0).toString())),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: "Ürünü Düzenle",
                        child: IconButton(
                          icon: Icon(Icons.edit_note, color: Colors.blueAccent.shade700, size: 22),
                          onPressed: () {
                            // _showAddEditProductDialog çağırmadan önce product ve product['id'] kontrolü
                            if (product != null && product['id'] != null) {
                              _showAddEditProductDialog(product: product);
                            } else {
                              print("HATA: Düzenlenecek ürün veya ID'si bulunamadı!");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ürün bilgileri eksik, düzenlenemiyor.'), backgroundColor: Colors.red),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: "Ürünü Sil",
                        child: IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 22),
                      onPressed: () {
                            // _deleteProduct çağırmadan önce product ve product['id'] kontrolü
                            if (product != null && product['id'] != null) {
                              _deleteProduct(product['id'].toString());
                            } else {
                              print("HATA: Silinecek ürün veya ID'si bulunamadı!");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ürün bilgileri eksik, silinemiyor.'), backgroundColor: Colors.red),
                              );
                            }
                          },
                        ),
                    ),
                  ],
                  ),
                ),
              ],
            );
            }).toList(),
        ),
      ),
    );
  }
} 