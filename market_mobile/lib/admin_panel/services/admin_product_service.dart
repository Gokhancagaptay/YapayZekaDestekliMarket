import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AdminProductService {
  final String _baseUrl = kIsWeb ? 'http://localhost:8000/api/products' : 'http://10.0.2.2:8000/api/products';

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> fetchProducts({String? searchTerm, String? category}) async {
    print('AdminProductService: Urunler API\'den yukleniyor (Arama: $searchTerm, Kategori: $category)...');
    try {
      Map<String, String> queryParams = {};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      Uri uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // Backend List[ProductResponse] dönüyor, yani direkt bir liste.
        final List<dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        
        // DEBUG: Gelen her bir ürün datasını ve id'sini logla
        //responseData.forEach((productData) {
        //  print('AdminProductService DEBUG: Gelen productData: $productData');
        //  print('AdminProductService DEBUG: productData[\'id\']: ${productData?['id']}'); 
        //});

        final List<Map<String, dynamic>> productsList = responseData.map((productDataRaw) {
          final productData = productDataRaw as Map<String, dynamic>; // Tip dönüşümü
          // Backend _id'yi id olarak döndürüyor DEMİŞTİK AMA DEBUG LOGLARI _id GELDİĞİNİ GÖSTERİYOR.
          // BU YÜZDEN productData['_id'] KULLANACAĞIZ.
          print('AdminProductService DEBUG: Maplenen productData: $productData, _id degeri: ${productData['_id']}'); 
          return {
            'id': productData['_id']?.toString(), // _id'yi al ve string'e çevir.
            'name': productData['name'] ?? 'Isimsiz Urun',
            'price': (productData['price'] as num?)?.toDouble() ?? 0.0,
            'stock': (productData['stock' ] as num?)?.toInt() ?? 0,
            'image_url': productData['image_url'] ?? '',
            'category': productData['category'] ?? 'Kategorisiz',
          };
        }).toList();
        print('AdminProductService: ${productsList.length} urun API\'den yuklendi.');
        return productsList;
      } else {
        print('AdminProductService: Urun yukleme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        throw Exception('Urunler API\'den yuklenemedi. Durum: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminProductService: Urun yukleme API cagrisi hatasi: $e');
      throw Exception('Urun yukleme sirasinda bir hata olustu: $e');
    }
  }

  Future<List<String>> fetchCategories() async {
    print('AdminProductService: Kategoriler API\'den yukleniyor...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'), 
        headers: await _getHeaders()
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((category) => category.toString()).toList();
      } else {
        print('AdminProductService: Kategori yukleme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        throw Exception('Kategoriler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('AdminProductService: Kategori API cagrisi hatasi: $e');
      throw Exception('Kategoriler yüklenirken bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    print('AdminProductService: Urun ekleniyor: ${productData['name']}');
    try {
      final response = await http.post(
        Uri.parse(_baseUrl), // POST /api/products/
        headers: await _getHeaders(),
        body: json.encode(productData),
      );

      if (response.statusCode == 200) { // Genellikle 201 Created döner ama API'miz 200 ve ürünü dönüyor
        print('AdminProductService: Urun basariyla eklendi.');
        final Map<String, dynamic> responseBody = json.decode(utf8.decode(response.bodyBytes));
        // Backend'den gelen id'yi de ekleyelim
        return {
            'id': responseBody['id'], 
            'name': responseBody['name'] ?? 'Isimsiz Urun',
            'price': (responseBody['price'] as num?)?.toDouble() ?? 0.0,
            'stock': (responseBody['stock' ] as num?)?.toInt() ?? 0,
            'image_url': responseBody['image_url'] ?? '',
            'category': responseBody['category'] ?? 'Kategorisiz',
          };
      } else {
        print('AdminProductService: Urun ekleme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Urun eklenemedi: ${errorBody["detail"] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('AdminProductService: Urun ekleme API cagrisi hatasi: $e');
      throw Exception('Urun eklenirken bir hata olustu: $e');
    }
  }

  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> productUpdateData) async {
    print('AdminProductService: Urun ($productId) guncelleniyor...');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$productId'),
        headers: await _getHeaders(),
        body: json.encode(productUpdateData),
      );

      if (response.statusCode == 200) {
        print('AdminProductService: Urun ($productId) basariyla guncellendi.');
        final Map<String, dynamic> responseBody = json.decode(utf8.decode(response.bodyBytes));
        return {
            'id': responseBody['id'], 
            'name': responseBody['name'] ?? 'Isimsiz Urun',
            'price': (responseBody['price'] as num?)?.toDouble() ?? 0.0,
            'stock': (responseBody['stock' ] as num?)?.toInt() ?? 0,
            'image_url': responseBody['image_url'] ?? '',
            'category': responseBody['category'] ?? 'Kategorisiz',
          };
      } else {
        print('AdminProductService: Urun guncelleme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Urun guncellenemedi: ${errorBody["detail"] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('AdminProductService: Urun guncelleme API cagrisi hatasi: $e');
      throw Exception('Urun guncellenirken bir hata olustu: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    print('AdminProductService: Urun ($productId) siliniyor...');
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$productId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        print('AdminProductService: Urun ($productId) basariyla silindi.');
      } else {
        print('AdminProductService: Urun silme hatasi - Durum: ${response.statusCode}, Mesaj: ${response.body}');
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception('Urun silinemedi: ${errorBody["detail"] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('AdminProductService: Urun silme API cagrisi hatasi: $e');
      throw Exception('Urun silinirken bir hata olustu: $e');
    }
  }
} 