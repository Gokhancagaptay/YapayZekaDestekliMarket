import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItemTile extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  const CartItemTile({
    Key? key,
    required this.product,
    required this.qty,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('${product.price.toStringAsFixed(2)} ₺'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            icon: const Icon(Icons.remove),
            splashRadius: 16,
            onPressed: onDec),
        Text('$qty'),
        IconButton(
            icon: const Icon(Icons.add),
            splashRadius: 16,
            onPressed: onInc),
        IconButton(
            icon: const Icon(Icons.close),
            splashRadius: 16,
            onPressed: onRemove),
      ]),
    );
  }
}
