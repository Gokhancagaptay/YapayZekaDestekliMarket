class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['_id'] ?? json['id'] ?? json['name'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        stock: json['stock'],
        imageUrl: json['image_url'] ?? '',
      );
}
