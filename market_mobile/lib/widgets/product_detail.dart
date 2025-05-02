import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailPage extends StatelessWidget {
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Detail'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.network(
              imageUrl,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              style: const TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('vitamin A')),
                Chip(label: Text('vitamin C')),
                Chip(label: Text('vitamin K')),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16, left: 16),
            child: Text(
              'Ingredients',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundImage: NetworkImage("https://via.placeholder.com/32")),
                SizedBox(width: 8),
                CircleAvatar(radius: 16, backgroundImage: NetworkImage("https://via.placeholder.com/32")),
                SizedBox(width: 8),
                CircleAvatar(radius: 16, backgroundImage: NetworkImage("https://via.placeholder.com/32")),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '₺${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    cart.addItem(
                      CartItem(name: name, price: price, imageUrl: imageUrl),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ürün sepete eklendi")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
