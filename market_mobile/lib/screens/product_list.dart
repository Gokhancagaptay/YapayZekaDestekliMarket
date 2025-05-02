import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/product_card.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'cart_screen.dart';

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  } else {
    return 'http://localhost:8000';
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
    final url = Uri.parse("${getBaseUrl()}/products/?category=$selectedCategory");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        products = json["products"];
      });
    } else {
      setState(() {
        products = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Icon(Icons.account_circle, color: Colors.white, size: 32),
                SizedBox(height: 4),
                Text(
                  "Find the Best\nHealth for You",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  categories.firstWhere((element) => element['key'] == selectedCategory)['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
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
                    imageUrl: product["image_url"],
                    name: product["name"],
                    price: (product["price"] as num).toDouble(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Icon(Icons.home, color: Colors.black87),
                  Icon(Icons.settings_outlined, color: Colors.black54),
                  Icon(Icons.shopping_cart_outlined, color: Colors.black54),
                  Icon(Icons.person_outline, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
