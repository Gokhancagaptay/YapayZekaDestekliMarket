import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:market_mobile/models/order_model.dart';
import 'package:market_mobile/services/order_service.dart';
// import 'package:market_mobile/theme/app_theme.dart'; // Renkler için tema dosyanızın yolu

// Tema renklerini burada tanımlayalım (projenizdeki theme dosyasından almanız daha iyi olur)
const Color bgColor = Color(0xFF232323);
const Color orangeAccent = Color(0xFFF2552C);
const Color textColorWhite = Color(0xFFFFFFFF);
const Color textColorLightGrey = Color(0xFFBDBDBD);

class OrderScreen extends StatefulWidget {
  final bool inPanel;
  const OrderScreen({Key? key, this.inPanel = false}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<OrderModel>> _ordersFuture;
  String _selectedFilter = 'Tümü'; // Aktif, Tamamlanan, Tümü
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }
  
  void _refreshOrders() {
    print('🔄 Siparişler yenileniyor...');
    setState(() {
      _ordersFuture = _fetchOrders();
    });
  }
  
  Future<List<OrderModel>> _fetchOrders() async {
    try {
      print('📋 Siparişler yükleniyor...');
      
      // HTTP ile siparişleri al
      print('🔄 HTTP yöntemi ile siparişler getiriliyor...');
      final httpOrders = await _orderService.fetchOrdersHttp();
      
      if (httpOrders.isNotEmpty) {
        print('✅ HTTP ile ${httpOrders.length} sipariş başarıyla yüklendi');
        return httpOrders;
      }
      
      print('ℹ️ HTTP ile sipariş bulunamadı, Stream yöntemi deneniyor...');
      // Stream'i dinleyerek ilk değeri al
      List<OrderModel> orders = await _orderService.getOrders().first;
      print('✅ Stream ile ${orders.length} sipariş başarıyla yüklendi');
      return orders;
    } catch (e) {
      print('❌ Siparişler yüklenirken hata: $e');
      return [];
    }
  }

  List<OrderModel> _filterAndSearchOrders(List<OrderModel> orders) {
    List<OrderModel> filteredOrders = orders;

    // Filtreleme
    if (_selectedFilter == 'Aktif') {
      filteredOrders = orders.where((order) => order.status == 'active').toList();
    } else if (_selectedFilter == 'Tamamlanan') {
      filteredOrders = orders.where((order) => order.status == 'completed').toList();
    }

    // Arama
    if (_searchTerm.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        final searchTermLower = _searchTerm.toLowerCase();
        final orderDate = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order.timestamp));
        bool matchesProduct = order.products.any((product) => product['name'].toString().toLowerCase().contains(searchTermLower));
        bool matchesDate = orderDate.contains(searchTermLower);
        return matchesProduct || matchesDate;
      }).toList();
    }
    return filteredOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Siparişlerim', style: TextStyle(color: textColorWhite, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColorWhite),
        actions: [
          // Yenileme butonu
          IconButton(
            icon: Icon(Icons.refresh, color: textColorWhite),
            onPressed: _refreshOrders,
            tooltip: 'Siparişleri Yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Arama ve filtreleme bölümü
            _buildFilterAndSearchBar(),
            
            // Siparişler listesi
            Expanded(
              child: FutureBuilder<List<OrderModel>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  // Yükleme durumu
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: orangeAccent),
                          const SizedBox(height: 16),
                          Text('Siparişleriniz yükleniyor...', 
                            style: TextStyle(color: textColorLightGrey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Hata durumu
                  if (snapshot.hasError) {
                    print(snapshot.error); // Hata ayıklama için
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Siparişler yüklenirken bir hata oluştu.', 
                            style: TextStyle(color: textColorLightGrey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh, size: 16),
                            label: Text('Yeniden Dene'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _refreshOrders,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Veri yok durumu
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: textColorLightGrey, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz siparişiniz yok.',
                            style: TextStyle(color: textColorLightGrey, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alışverişe başlayarak ilk siparişinizi oluşturun.',
                            style: TextStyle(color: textColorLightGrey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Filtreleme uygula
                  final allOrders = snapshot.data!;
                  final displayedOrders = _filterAndSearchOrders(allOrders);

                  // Filtreleme sonucu veri yok
                  if (displayedOrders.isEmpty && (_searchTerm.isNotEmpty || _selectedFilter != 'Tümü')) {
                     return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: textColorLightGrey, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Arama kriterlerinize uygun sipariş bulunamadı.',
                            style: TextStyle(color: textColorLightGrey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchTerm = '';
                                _selectedFilter = 'Tümü';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: orangeAccent,
                              side: BorderSide(color: orangeAccent),
                            ),
                            child: Text('Filtreleri Temizle'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Platformu algılama
                  bool isWeb = MediaQuery.of(context).size.width > 600;

                  // Sipariş listesini göster
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (isWeb) {
                        // Web platformunda, içeriği sınırlandırmak için ek bir tasarım kullanıyoruz
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 1.5, // Daha geniş kartlar
                            ),
                            itemCount: displayedOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(displayedOrders[index]);
                            },
                          ),
                        );
                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: displayedOrders.length,
                          // Öğeler arasında biraz boşluk ekleyelim
                          itemExtent: null, // Otomatik yükseklik
                          itemBuilder: (context, index) {
                            return _buildOrderCard(displayedOrders[index]);
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Arama Çubuğu
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              style: TextStyle(color: textColorWhite),
              decoration: InputDecoration(
                hintText: 'Sipariş veya ürün ara...',
                hintStyle: TextStyle(color: textColorLightGrey.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: orangeAccent.withOpacity(0.8), size: 22),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Modern Filtre Butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton('Tümü', Icons.all_inclusive),
              _buildFilterButton('Aktif', Icons.local_shipping),
              _buildFilterButton('Tamamlanan', Icons.check_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter, IconData icon) {
    bool isActive = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isActive 
                ? LinearGradient(
                    colors: [orangeAccent.withOpacity(0.8), orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive 
                ? [
                    BoxShadow(
                      color: orangeAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ] 
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : textColorLightGrey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                filter,
                style: TextStyle(
                  color: isActive ? Colors.white : textColorLightGrey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.timestamp);

    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        splashColor: orangeAccent.withOpacity(0.1),
        highlightColor: orangeAccent.withOpacity(0.05),
        onTap: () {
          // Sipariş detaylarını göstermek için dialog aç
          _showOrderDetailsDialog(order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sipariş başlığı ve tarihi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sipariş numarası
                  Expanded(
                    child: Text(
                      order.orderNumber.isNotEmpty 
                          ? 'Sipariş #${order.orderNumber}' 
                          : 'Sipariş #${order.orderId.substring(0, 8)}...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: orangeAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Sipariş tarihi
                  Text(
                    dateFormat.format(orderDate),
                    style: TextStyle(fontSize: 12, color: textColorLightGrey),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Durum etiketi
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status == 'active' ? Colors.blue.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status == 'active' ? 'Aktif Sipariş' : 'Tamamlandı',
                  style: TextStyle(color: textColorWhite, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ürünlerin listesi (ilk 3 ürün)
              ...order.products.take(3).map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: textColorLightGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${product['name']} (x${product['quantity']})',
                        style: TextStyle(fontSize: 14, color: textColorWhite),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              // Eğer 3'ten fazla ürün varsa
              if (order.products.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 14.0),
                  child: Text(
                    '+ ${order.products.length - 3} ürün daha',
                    style: TextStyle(fontSize: 12, color: textColorLightGrey, fontStyle: FontStyle.italic),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Fiyat ve detay göster butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toplam fiyat
                  Text(
                    'Toplam: ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(order.totalPrice)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: orangeAccent),
                  ),
                  
                  // Detay görüntüleme butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 16, color: textColorWhite),
                      onPressed: () {
                        _showOrderDetailsDialog(order);
                      },
                      tooltip: 'Sipariş Detaylarını Göster',
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      splashRadius: 24,
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
  
  // Sipariş detaylarını gösteren dialog
  void _showOrderDetailsDialog(OrderModel order) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.timestamp);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve kapatma butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.orderNumber.isNotEmpty 
                            ? 'Sipariş #${order.orderNumber}' 
                            : 'Sipariş #${order.orderId.substring(0, 8)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorWhite),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textColorLightGrey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Sipariş zamanı
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: textColorLightGrey),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(orderDate),
                          style: TextStyle(fontSize: 14, color: textColorLightGrey),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Durum
                    Row(
                      children: [
                        Text('Durum: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColorWhite)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == 'active' ? Colors.blue.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status == 'active' ? 'Aktif Sipariş' : 'Tamamlandı',
                            style: TextStyle(color: textColorWhite, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Ürünler başlığı
                    Text(
                      'Ürünler',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: orangeAccent),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Ürünlerin listesi
                    ...order.products.map((product) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${product['name']}',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColorWhite),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product['quantity']} adet x ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(product['price'])}',
                                  style: TextStyle(fontSize: 13, color: textColorLightGrey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(product['price'] * product['quantity'])}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColorWhite),
                          ),
                        ],
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 5),
                    Divider(color: textColorLightGrey.withOpacity(0.3)),
                    const SizedBox(height: 5),
                    
                    // Toplam Fiyat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Toplam: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColorWhite),
                        ),
                        Text(
                          '${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(order.totalPrice)}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: orangeAccent),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Teslimat Bilgileri
                    Text(
                      'Teslimat Bilgileri',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: orangeAccent),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Adres
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 18, color: textColorLightGrey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.address['full'] ?? '${order.address['mahalle'] ?? ''} ${order.address['sokak'] ?? ''} No:${order.address['binaNo'] ?? ''} Kat:${order.address['kat'] ?? ''} Daire:${order.address['daireNo'] ?? ''}',
                            style: TextStyle(fontSize: 14, color: textColorWhite),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Ödeme Yöntemi
                    Row(
                      children: [
                        Icon(Icons.payment, size: 18, color: textColorLightGrey),
                        const SizedBox(width: 10),
                        Text(
                          'Ödeme Yöntemi: ${order.paymentMethod}',
                          style: TextStyle(fontSize: 14, color: textColorWhite),
                        ),
                      ],
                    ),
                    
                    if (order.lastFourDigits != null && order.lastFourDigits!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Row(
                          children: [
                            Icon(Icons.credit_card, size: 18, color: textColorLightGrey),
                            const SizedBox(width: 10),
                            Text(
                              'Kart: **** **** **** ${order.lastFourDigits}',
                              style: TextStyle(fontSize: 14, color: textColorWhite),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 30),
                    
                    // İşlem Butonları
                    if (order.status == 'active')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text('Tamamlandı Olarak İşaretle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              Navigator.pop(context); // Dialog'u kapat
                              await _orderService.updateOrderStatus(order.orderId, 'completed');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sipariş tamamlandı olarak işaretlendi.'), backgroundColor: Colors.green),
                              );
                              _refreshOrders();
                            } catch (e) {
                              print('❌ Sipariş durumu güncellenirken hata: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sipariş durumu güncellenirken hata: $e'), backgroundColor: Colors.red),
                              );
                            }
                          },
                        ),
                      ),
                    
                    if (order.status == 'completed' && order.rating == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.star, color: Colors.white),
                          label: Text('Siparişi Değerlendir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Dialog'u kapat
                            _showRatingDialog(order);
                          },
                        ),
                      ),
                    
                    if (order.status == 'completed' && order.rating != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Değerlendirmeniz',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: orangeAccent),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (int i = 0; i < 5; i++)
                                Icon(
                                  i < order.rating! ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                '${order.rating}/5',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingSection(OrderModel order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.rating == null)
          ElevatedButton.icon(
            icon: Icon(Icons.star_border, color: textColorWhite, size: 14),
            label: Text('Değerlendir', style: TextStyle(color: textColorWhite, fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: orangeAccent.withOpacity(0.9),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: () => _showRatingDialog(order),
          )
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text('Puan: ', style: TextStyle(color: textColorLightGrey, fontSize: 11)),
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < order.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showRatingDialog(OrderModel order) {
    int? currentRating;
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: bgColor.withOpacity(0.95),
              title: Text(
                'Siparişi Değerlendir', 
                style: TextStyle(color: textColorWhite, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          order.orderNumber.isNotEmpty 
                              ? 'Sipariş #${order.orderNumber}' 
                              : 'Sipariş #${order.orderId.substring(0,8)}', 
                          style: TextStyle(
                            color: orangeAccent, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // İlk iki ürünü göster
                        ...order.products.take(2).map((product) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Text(
                            '${product['name']} (x${product['quantity']})',
                            style: TextStyle(color: textColorWhite, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        )).toList(),
                        // Ürün sayısı 2'den fazlaysa
                        if (order.products.length > 2)
                          Text(
                            '+ ${order.products.length - 2} ürün daha',
                            style: TextStyle(color: textColorLightGrey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bu siparişi nasıl değerlendirirsiniz?',
                    style: TextStyle(color: textColorLightGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            currentRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            currentRating != null && currentRating! > index ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (currentRating != null) ...[
                    const SizedBox(height: 15),
                    Text(
                      _getRatingText(currentRating!),
                      style: TextStyle(
                        color: Colors.amber, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.close, size: 18),
                      label: Text('İptal'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: textColorLightGrey,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.send, size: 18),
                      label: Text('Değerlendir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: currentRating == null ? null : () async {
                        if (currentRating != null) {
                          try {
                            print('⭐ Sipariş değerlendiriliyor: ${order.orderId} - $currentRating yıldız');
                            await _orderService.updateOrderRating(order.orderId, currentRating!);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Değerlendirmeniz için teşekkürler!'),
                                  ],
                                ), 
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Sayfayı yenile
                            _refreshOrders();
                          } catch (e) {
                            print('❌ Değerlendirme kaydedilirken hata: $e');
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Değerlendirme kaydedilirken hata: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  // Yıldız sayısına göre değerlendirme metni
  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return "Kötü";
      case 2: return "İdare Eder";
      case 3: return "Orta";
      case 4: return "İyi";
      case 5: return "Mükemmel";
      default: return "";
    }
  }
}

// Ödeme ekranında sipariş kaydetme örneği:
// Bu kısım, ödeme ekranınızdaki "Ödemeyi Tamamla" butonunun onPressed metodunda yer alacak.
//
// final OrderService _orderService = OrderService();
//
// void _completePaymentAndSaveOrder() async {
//   // Gerekli verileri topla (sepet, adres, ödeme yöntemi vb.)
//   List<Map<String, dynamic>> productsFromCart = [
//     {'name': 'Ürün A', 'quantity': 1, 'price': 100.0},
//     {'name': 'Ürün B', 'quantity': 2, 'price': 50.0}
//   ];
//   double totalPrice = 200.0;
//   String paymentMethod = 'Kredi Kartı';
//   Map<String, String> deliveryAddress = {'street': '123 Örnek Sok.', 'city': 'Ankara', 'zipCode': '06000'};
//   String? cardLastFour = '1234'; // Eğer kredi kartı ise
//
//   // OrderModel oluştur (orderId ve userId OrderService içinde atanacak)
//   OrderModel newOrder = OrderModel(
//     orderId: '', // OrderService'de oluşturulacak
//     userId: '', // OrderService'de alınacak
//     products: productsFromCart,
//     totalPrice: totalPrice,
//     paymentMethod: paymentMethod,
//     address: deliveryAddress,
//     lastFourDigits: cardLastFour,
//     timestamp: DateTime.now().millisecondsSinceEpoch, // OrderService'de de ayarlanabilir, burada da
//     status: 'active', // Yeni sipariş aktif olarak başlar
//   );
//
//   try {
//     await _orderService.addOrder(newOrder);
//     // Başarılı mesajı göster, kullanıcıyı sipariş ekranına yönlendir vb.
//     print('Sipariş başarıyla Firebase'e kaydedildi!');
//     // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderScreen()));
//   } catch (e) {
//     // Hata mesajı göster
//     print('Sipariş kaydedilirken hata: $e');
//   }
// }


