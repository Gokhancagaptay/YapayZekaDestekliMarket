class OrderModel {
  final String orderId;
  final String userId;
  final String orderNumber; // Kullanıcı dostu sipariş numarası
  final List<Map<String, dynamic>> products; // { 'name': 'Ürün Adı', 'quantity': 2, 'price': 25.0 }
  final double totalPrice;
  final String paymentMethod;
  final Map<String, String> address; // { 'street': 'Sokak Adı', 'city': 'Şehir', 'zipCode': 'Posta Kodu' }
  final String? lastFourDigits; // Kredi kartının son 4 hanesi, opsiyonel
  final int timestamp;
  final String status; // Örneğin: 'active', 'completed'
  int? rating; // 1-5 arası yıldız, opsiyonel

  OrderModel({
    required this.orderId,
    required this.userId,
    this.orderNumber = '', // Varsayılan değer boş string
    required this.products,
    required this.totalPrice,
    required this.paymentMethod,
    required this.address,
    this.lastFourDigits,
    required this.timestamp,
    this.status = 'active', // Varsayılan olarak aktif
    this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'orderNumber': orderNumber,
      'products': products,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'address': address,
      'lastFourDigits': lastFourDigits,
      'timestamp': timestamp,
      'status': status,
      'rating': rating,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrderModel(
        orderId: json['orderId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        orderNumber: json['orderNumber'] as String? ?? '', // Eski siparişlerde bu alan olmayabilir
        products: json.containsKey('products') && json['products'] != null 
            ? (json['products'] as List<dynamic>)
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList()
            : [], // Boş liste oluştur
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: json['paymentMethod'] as String? ?? 'Bilinmiyor',
        address: json.containsKey('address') && json['address'] != null
            ? Map<String, String>.from(json['address'] as Map)
            : {'full': 'Adres bilgisi bulunamadı'},
        lastFourDigits: json['lastFourDigits'] as String?,
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        status: json['status'] as String? ?? 'active',
        rating: json['rating'] as int?,
      );
    } catch (e) {
      print('❌ OrderModel oluşturulurken hata: $e');
      print('❌ Sorunlu JSON: $json');
      // Firebase'den hatalı veri gelse bile bir model oluştur
      return OrderModel(
        orderId: json['orderId'] as String? ?? 'error_id',
        userId: json['userId'] as String? ?? 'error_user',
        orderNumber: 'error',
        products: [],
        totalPrice: 0.0,
        paymentMethod: 'Bilinmiyor',
        address: {'full': 'Hatalı adres verisi'},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: 'error',
        rating: null,
      );
    }
  }
} 