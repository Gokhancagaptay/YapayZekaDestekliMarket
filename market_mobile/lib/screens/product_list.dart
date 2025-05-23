import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';  // TimeoutException için gerekli import
import '../widgets/product_card.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stock_screen.dart';


String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else {
    return 'http://10.0.2.2:8000';
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  String selectedCategory = "meyve_sebze";

  final List<Map<String, String>> categories = [
    {"key": "meyve_sebze", "title": "Meyve ve Sebzeler"},
    {"key": "et_tavuk", "title": "Et ve Tavuk"},
    {"key": "sut_urunleri", "title": "Süt Ürünleri"},
    {"key": "icecekler", "title": "İçecekler"},
    {"key": "atistirmalik", "title": "Atıştırmalık"},
    {"key": "temizlik", "title": "Temizlik"},
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

Future<void> fetchProducts() async {
  try {
    final url = Uri.parse("${getBaseUrl()}/products/by-category/$selectedCategory");
    print("İstek URL: $url");
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Bağlantı zaman aşımına uğradı');
      },
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json["products"] != null) {
        setState(() {
          products = json["products"];
        });
      } else {
        print("Ürün verisi bulunamadı");
        setState(() {
          products = [];
        });
      }
    } else {
      print("HATA: ${response.statusCode} - ${response.body}");
      setState(() {
        products = [];
      });
      // Hata mesajını göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürünler yüklenirken bir hata oluştu: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print("Bağlantı hatası: $e");
    setState(() {
      products = [];
    });
    // Hata mesajını göster
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _showSidePanel(BuildContext context, Widget child) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Kapat",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF232323),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(-8, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // WEB TASARIMI
      return Scaffold(
        backgroundColor: const Color(0xFF232323),
        appBar: AppBar(
          backgroundColor: const Color(0xFF232323),
          elevation: 0,
          toolbarHeight: 80,
          title: Row(
            children: [
              const Icon(Icons.shopping_basket, color: Colors.deepOrange, size: 36),
              const SizedBox(width: 12),
              const Text(
                "Online Market",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: 0.5),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                onPressed: () {
                  _showSidePanel(context, const ProfileScreen(inPanel: true));
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return cart.itemCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  _showSidePanel(context, const CartScreen());
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white70, size: 26),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Row(
          children: [
            // Sol Menü (Kategoriler)
            Container(
              width: 220,
              color: const Color(0xFF232323),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Kategoriler",
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...categories.map((item) {
                    final isSelected = selectedCategory == item["key"];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tileColor: const Color(0xFF232323),
                        leading: Icon(Icons.label, color: Colors.white),
                        title: Text(
                          item["title"]!,
                          style: TextStyle(
                            color: isSelected ? Colors.deepOrange : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedCategory = item["key"]!;
                            fetchProducts();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            // Sağ Grid (Ürünler)
            Expanded(
              child: Container(
                color: const Color(0xFF282828),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categories.firstWhere((element) => element['key'] == selectedCategory)['title'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 3;
                            if (constraints.maxWidth > 1200) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth < 900) {
                              crossAxisCount = 2;
                            }
                            return GridView.builder(
                              itemCount: products.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 3 / 4,
                              ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ProductCard(
                                    id: product["id"] ?? product["_id"] ?? product["name"],
                                    imageUrl: product["image_url"],
                                    name: product["name"],
                                    price: (product["price"] as num).toDouble(),
                                    stock: product["stock"] ?? 0,
                                    category: product["category"] ?? selectedCategory,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // MOBİL TASARIM (mevcut haliyle)
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen(inPanel: true)),
                        );
                      },
                      child: const Icon(Icons.account_circle, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Find the Best\nHealth for You",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
    ),
    const Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: Icon(Icons.notifications_none, color: Colors.white70, size: 20),
    ),
  ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];
                final isSelected = selectedCategory == item["key"];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    label: Text(
                      item["title"]!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.deepOrangeAccent,
                    backgroundColor: Colors.white,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = item["key"]!;
                        fetchProducts();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                categories.firstWhere((element) => element['key'] == selectedCategory)['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3 / 4,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    id: product["id"] ?? product["_id"] ?? product["name"],
                    imageUrl: product["image_url"],
                    name: product["name"],
                    price: (product["price"] as num).toDouble(),
                    stock: product["stock"] ?? 0,
                    category: product["category"] ?? selectedCategory,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(Icons.home, color: Colors.black87),
                  const Icon(Icons.settings_outlined, color: Colors.black54),
                  Stack(
                    children: [
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Consumer<CartProvider>(
                                builder: (context, cart, child) {
                                  return cart.itemCount > 0
                                      ? Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.deepOrange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${cart.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          _showSidePanel(context, const CartScreen());
                        },
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen(inPanel: true)),
                      );
                    },
                    child: const Icon(Icons.person_outline, color: Colors.black54),
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
