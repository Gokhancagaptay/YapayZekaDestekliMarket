class StockItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double quantity;
  final String unit;
  final String? expiryDate;
  final String? notes;

  StockItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'image_url': imageUrl,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate,
      'notes': notes,
    };
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      productId: json['product_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'adet',
      expiryDate: json['expiry_date'],
      notes: json['notes'],
    );
  }
} 