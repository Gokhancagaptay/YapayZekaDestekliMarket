// lib/services/cart_service.dart

import '../models/product.dart';

class CartService {
  static List<Product> cartItems = [];

  static void addToCart(Product product) {
    cartItems.add(product);
  }

  static int getCartCount() {
    return cartItems.length;
  }

  static List<Product> getCartItems() {
    return cartItems;
  }

  static void clearCart() {
    cartItems.clear();
  }
}