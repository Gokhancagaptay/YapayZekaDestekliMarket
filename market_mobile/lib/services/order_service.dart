import 'package:firebase_database/firebase_database.dart';
import 'package:market_mobile/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Firebase Realtime Database URL (Firebase konsol ayarlarından alınmalı)
  final String _firebaseDbUrl = "https://marketonline44-default-rtdb.firebaseio.com";
  
  // Firebase bağlantı durumunu test eden yardımcı metot
  Future<bool> checkConnection() async {
    try {
      print('🔄 Firebase bağlantısı kontrol ediliyor...');
      // HTTP ile doğrudan bağlantı kontrolü
      final response = await http.get(Uri.parse("$_firebaseDbUrl/.json?shallow=true"));
      if (response.statusCode == 200) {
        print('✅ Firebase bağlantısı başarılı: ${response.statusCode}');
        return true;
      } else if (response.statusCode == 404) {
        print('⚠️ Firebase URL bulunamadı (404). Firebase URL\'nizi kontrol edin: $_firebaseDbUrl');
        print('⚠️ Hata detayı: ${response.body}');
        // 2 saniye bekleyip işleme devam et (geliştirme için)
        await Future.delayed(Duration(seconds: 2)); 
        // Hata mesajı görüntülendikten sonra işleme devam edebilirsiniz
        return true; // Geliştirme sırasında teste devam etmek için
      } else {
        print('❌ Firebase bağlantı hatası: HTTP ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Firebase bağlantı hatası: $e');
      return false;
    }
  }

  // SharedPreferences'tan kullanıcı ID'sini almak için yardımcı metot
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      print('👤 Kullanıcı ID alındı: $uid');
    } else {
      print('❌ Kullanıcı ID bulunamadı');
    }
    return uid;
  }

  // Firebase'e doğrudan HTTP ile sipariş ekleyen metot
  Future<void> _directFirebaseAdd(String userId, Map<String, dynamic> orderData) async {
    try {
      print('🔄 HTTP ile Firebase\'e doğrudan sipariş ekleniyor...');
      final url = "$_firebaseDbUrl/orders/$userId.json";
      print('🔍 Firebase URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(orderData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Firebase\'e sipariş başarıyla eklendi. Oluşturulan ID: ${data['name']}');
      } else {
        print('❌ Firebase\'e sipariş eklenemedi. HTTP ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        throw Exception('Firebase HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Firebase HTTP hatası: $e');
      rethrow;
    }
  }

  // Yeni sipariş ekleme
  Future<void> addOrder(OrderModel order) async {
    print('🛒 Sipariş ekleme işlemi başlatıldı');
    final isConnected = await checkConnection();
    
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için sipariş eklenemedi');
      throw Exception('User not logged in');
    }
    
    try {
      print('📝 Sipariş detayları: ${order.products.length} ürün, toplam: ${order.totalPrice} TL');
      print('💳 Ödeme yöntemi: ${order.paymentMethod}');
      
      // Database referansını oluştur
      final databasePath = 'orders/$userId';
      print('🔍 Firebase path: $databasePath');
      
      // OrderId oluştur (manual)
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      print('🔑 Oluşturulan sipariş ID: $orderId');
      
      // OrderNumber'ı güncelleyerek tam bir OrderModel oluşturuyoruz
      final newOrder = OrderModel(
        orderId: orderId,
        userId: userId,
        orderNumber: order.orderNumber,
        products: order.products,
        totalPrice: order.totalPrice,
        paymentMethod: order.paymentMethod,
        address: order.address,
        lastFourDigits: order.lastFourDigits,
        timestamp: DateTime.now().millisecondsSinceEpoch, // Her zaman güncel timestamp
        status: order.status,
        rating: order.rating,
      );
      
      // Modeli JSON'a dönüştür
      final orderJson = newOrder.toJson();
      print('📄 Firebase\'e gönderilecek veri: ${orderJson.length} byte');
      
      // Firebase bağlantısı yoksa veya başarısız olursa, verileri yerel olarak kaydet
      if (!isConnected) {
        print('⚠️ Firebase bağlantısı yok. Sipariş yerel olarak kaydediliyor...');
        await _saveOrderLocally(newOrder);
        print('✅ Sipariş #${order.orderNumber} yerel olarak kaydedildi. İnternet bağlantısı geldiğinde senkronize edilecek.');
        return;
      }
      
      bool success = false;
      String errorMsg = "";
      
      // Önce HTTP yöntemi ile deneyelim (daha güvenilir)
      try {
        print('🔄 HTTP ile sipariş ekleniyor...');
        final url = "$_firebaseDbUrl/orders/$userId.json";
        final response = await http.post(
          Uri.parse(url),
          body: json.encode(orderJson),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ Firebase\'e sipariş HTTP ile başarıyla eklendi. Oluşturulan ID: ${data['name']}');
          success = true;
        } else {
          errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
          print('❌ Firebase\'e HTTP ile sipariş eklenemedi. $errorMsg');
        }
      } catch (httpError) {
        errorMsg = httpError.toString();
        print('⚠️ HTTP ile sipariş eklerken hata: $errorMsg. SDK ile denenecek...');
      }
      
      // HTTP başarısız olduysa SDK ile deneyelim
      if (!success) {
        try {
          print('🔄 Firebase SDK ile sipariş ekleniyor...');
          DatabaseReference orderRef = _database.ref(databasePath).push();
          await orderRef.set(orderJson);
          print('✅ Firebase SDK ile sipariş başarıyla kaydedildi. ID: ${orderRef.key}');
          success = true;
        } catch (sdkError) {
          errorMsg += " | SDK hatası: $sdkError";
          print('⚠️ Firebase SDK hatası: $sdkError.');
          
          // Son çare olarak yerel kayıt
          await _saveOrderLocally(newOrder);
          print('✅ Sipariş #${order.orderNumber} yerel olarak kaydedildi. İnternet bağlantısı geldiğinde senkronize edilecek.');
        }
      }
      
      if (!success) {
        print('❌ Sipariş eklenemedi. Tüm yöntemler başarısız oldu. Hatalar: $errorMsg');
        throw Exception('Order could not be added: $errorMsg');
      }
      
      print('✅ Sipariş #${order.orderNumber} işlemi tamamlandı');
      
    } catch (e) {
      print('❌ Sipariş ekleme hatası: $e');
      rethrow;
    }
  }
  
  // Siparişi yerel olarak kaydetme (bağlantı sorunu varsa)
  Future<void> _saveOrderLocally(OrderModel order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Daha önce kaydedilmiş siparişleri al
      List<String> savedOrders = prefs.getStringList('pendingOrders') ?? [];
      // Yeni siparişi ekle
      savedOrders.add(json.encode(order.toJson()));
      // Listeyi güncelle
      await prefs.setStringList('pendingOrders', savedOrders);
      print('📝 ${savedOrders.length} adet bekleyen sipariş var');
    } catch (e) {
      print('❌ Sipariş yerel olarak kaydedilemedi: $e');
      rethrow;
    }
  }

  // Kullanıcının siparişlerini getirme - HTTP ile
  Future<List<OrderModel>> fetchOrdersHttp() async {
    print('📋 HTTP ile siparişler yükleniyor...');
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için siparişler yüklenemedi');
      return [];
    }
    
    try {
      final url = "$_firebaseDbUrl/orders/$userId.json";
      print('🔍 HTTP ile siparişler yükleniyor. URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          print('ℹ️ Henüz sipariş bulunmuyor');
          return [];
        }
        
        final List<OrderModel> orders = [];
        data.forEach((key, value) {
          // Firebase'den gelen verilere orderId ekle
          value['orderId'] = key;
          try {
            orders.add(OrderModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('⚠️ Sipariş verisi ayrıştırılamadı: $e');
          }
        });
        
        // Siparişleri tarihe göre sırala (en yeni en üstte)
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        print('✅ HTTP ile ${orders.length} sipariş başarıyla yüklendi');
        return orders;
      } else {
        print('❌ HTTP ile siparişler yüklenemedi. HTTP ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ HTTP ile siparişler yüklenirken hata: $e');
      return [];
    }
  }

  // Kullanıcının siparişlerini getirme
  Stream<List<OrderModel>> getOrders() async* {
    print('📋 Siparişler yükleniyor...');
    final isConnected = await checkConnection();
    if (!isConnected) {
      print('❌ Firebase bağlantısı olmadığı için siparişler yüklenemedi');
      yield [];
      return;
    }
    
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için siparişler yüklenemedi');
      yield []; // Kullanıcı giriş yapmamışsa boş liste döndür
      return;
    }
    
    // Önce HTTP ile siparişleri al
    try {
      final httpOrders = await fetchOrdersHttp();
      yield httpOrders;
    } catch (e) {
      print('⚠️ HTTP ile siparişler yüklenemedi: $e. SDK deneniyor...');
    }
    
    final databasePath = 'orders/$userId';
    print('🔍 Siparişler SDK path: $databasePath');
    
    // FirebaseDatabase'in onValue akışını Stream<List<OrderModel>> olarak döndürmek için
    yield* _database.ref(databasePath).onValue.map((event) {
      final List<OrderModel> orders = [];
      DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.value != null) {
        try {
          print('📦 Firebase veri alındı: ${snapshot.key}');
          final Map<dynamic, dynamic> ordersMap = snapshot.value as Map<dynamic, dynamic>; 
          ordersMap.forEach((key, value) {
            value['orderId'] = key;  // orderId alanını ekle
            orders.add(OrderModel.fromJson(Map<String, dynamic>.from(value as Map)));
          });
          // Siparişleri tarihe göre sırala (en yeni en üstte)
          orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          print('✅ SDK ile ${orders.length} sipariş başarıyla yüklendi');
        } catch (e) {
          print('❌ Sipariş verilerini ayrıştırma hatası: $e');
        }
      } else {
        print('ℹ️ Henüz sipariş bulunmuyor');
      }
      return orders;
    });
  }

  // Sipariş değerlendirmesini güncelleme
  Future<void> updateOrderRating(String orderId, int rating) async {
    print('⭐ Sipariş değerlendirme işlemi başlatıldı: $orderId - $rating yıldız');
    final isConnected = await checkConnection();
    if (!isConnected) {
      print('❌ Firebase bağlantısı olmadığı için değerlendirme yapılamadı');
      throw Exception('Database connection failed');
    }
    
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için değerlendirme yapılamadı');
      throw Exception('User not logged in');
    }
    
    try {
      final databasePath = 'orders/$userId/$orderId';
      print('🔍 Değerlendirme path: $databasePath');
      
      // SDK ile güncelleme
      try {
        await _database
            .ref(databasePath)
            .update({'rating': rating, 'status': 'completed'});
        print('✅ SDK ile sipariş başarıyla değerlendirildi: $rating yıldız');
      } catch (sdkError) {
        print('⚠️ SDK ile değerlendirme yapılamadı: $sdkError. HTTP ile deneniyor...');
        
        // HTTP ile güncelleme
        final url = "$_firebaseDbUrl/orders/$userId/$orderId.json";
        final response = await http.patch(
          Uri.parse(url),
          body: json.encode({'rating': rating, 'status': 'completed'}),
        );
        
        if (response.statusCode == 200) {
          print('✅ HTTP ile sipariş başarıyla değerlendirildi: $rating yıldız');
        } else {
          print('❌ HTTP ile değerlendirme yapılamadı. HTTP ${response.statusCode}');
          print('❌ Hata detayı: ${response.body}');
          throw Exception('HTTP update error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Değerlendirme hatası: $e');
      rethrow;
    }
  }

  // Sipariş durumunu güncelleme (örneğin, 'tamamlandı' olarak işaretleme)
  Future<void> updateOrderStatus(String orderId, String status) async {
    print('🔄 Sipariş durumu güncelleme: $orderId - $status');
    final isConnected = await checkConnection();
    if (!isConnected) {
      print('❌ Firebase bağlantısı olmadığı için durum güncellenemedi');
      throw Exception('Database connection failed');
    }
    
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için durum güncellenemedi');
      throw Exception('User not logged in');
    }
    
    try {
      final databasePath = 'orders/$userId/$orderId';
      print('🔍 Durum güncelleme path: $databasePath');
      
      // SDK ile güncelleme
      try {
        await _database
            .ref(databasePath)
            .update({'status': status});
        print('✅ SDK ile sipariş durumu başarıyla güncellendi: $status');
      } catch (sdkError) {
        print('⚠️ SDK ile durum güncellenemedi: $sdkError. HTTP ile deneniyor...');
        
        // HTTP ile güncelleme
        final url = "$_firebaseDbUrl/orders/$userId/$orderId.json";
        final response = await http.patch(
          Uri.parse(url),
          body: json.encode({'status': status}),
        );
        
        if (response.statusCode == 200) {
          print('✅ HTTP ile sipariş durumu başarıyla güncellendi: $status');
        } else {
          print('❌ HTTP ile durum güncellenemedi. HTTP ${response.statusCode}');
          print('❌ Hata detayı: ${response.body}');
          throw Exception('HTTP update error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Durum güncelleme hatası: $e');
      rethrow;
    }
  }

  // Bekleyen siparişleri senkronize et
  Future<void> syncPendingOrders() async {
    print('🔄 Bekleyen siparişler senkronize ediliyor...');
    final isConnected = await checkConnection();
    if (!isConnected) {
      print('❌ Firebase bağlantısı olmadığı için senkronizasyon yapılamadı');
      return;
    }
    
    final userId = await _getUserId();
    if (userId == null) {
      print('❌ Kullanıcı oturumu bulunamadığı için senkronizasyon yapılamadı');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedOrders = prefs.getStringList('pendingOrders') ?? [];
      
      if (savedOrders.isEmpty) {
        print('ℹ️ Bekleyen sipariş bulunmuyor');
        return;
      }
      
      print('📋 ${savedOrders.length} adet bekleyen sipariş senkronize edilecek');
      List<String> failedOrders = [];
      
      for (int i = 0; i < savedOrders.length; i++) {
        try {
          final orderJson = json.decode(savedOrders[i]);
          print('🔄 Sipariş #${i+1} senkronize ediliyor...');
          
          // Firebase'e yükle
          try {
            // Database referansı
            final databasePath = 'orders/$userId';
            // SDK ile dene
            DatabaseReference orderRef = _database.ref(databasePath).push();
            await orderRef.set(orderJson);
            print('✅ Sipariş #${i+1} başarıyla senkronize edildi');
          } catch (sdkError) {
            print('⚠️ SDK ile senkronizasyon hatası: $sdkError. HTTP ile deneniyor...');
            try {
              await _directFirebaseAdd(userId, orderJson);
              print('✅ Sipariş #${i+1} HTTP ile senkronize edildi');
            } catch (httpError) {
              print('❌ Sipariş #${i+1} senkronize edilemedi: $httpError');
              failedOrders.add(savedOrders[i]);
            }
          }
        } catch (e) {
          print('❌ Sipariş #${i+1} işlenirken hata: $e');
          failedOrders.add(savedOrders[i]);
        }
      }
      
      // Başarısız siparişleri güncelle
      await prefs.setStringList('pendingOrders', failedOrders);
      print('✅ Senkronizasyon tamamlandı. ${savedOrders.length - failedOrders.length} sipariş başarılı, ${failedOrders.length} sipariş başarısız.');
    } catch (e) {
      print('❌ Senkronizasyon hatası: $e');
    }
  }
} 