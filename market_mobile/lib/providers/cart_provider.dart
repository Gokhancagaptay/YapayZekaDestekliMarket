import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double price;
  final String imageUrl;

  CartItem({
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get total {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }
}
