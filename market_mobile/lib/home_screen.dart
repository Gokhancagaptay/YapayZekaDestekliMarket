import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_item_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _productsFuture;
  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = ApiService.fetchProducts();
  }

  void _addToCart(Product p) =>
      setState(() => _cart[p] = (_cart[p] ?? 0) + 1);
  void _inc(Product p) => setState(() => _cart[p] = _cart[p]! + 1);
  void _dec(Product p) =>
      setState(() => _cart[p] == 1 ? _cart.remove(p) : _cart[p] = _cart[p]! - 1);
  void _remove(Product p) => setState(() => _cart.remove(p));

  double get _total =>
      _cart.entries.fold(0, (s, e) => s + e.key.price * e.value);

  Future<void> _showRecipe() async {
    final names = _cart.entries.map((e) => e.key.name).toList();
    if (names.isEmpty) return;
    final result = await ApiService.suggestRecipe(names);
    _dialog('Tarif Önerisi', result);
  }

  Future<void> _showAnalysis() async {
    final names = _cart.entries.map((e) => e.key.name).toList();
    if (names.isEmpty) return;
    final res = await ApiService.analyze(names);
    _dialog('Besin Analizi', res.toString());
  }

  void _dialog(String title, String msg) => showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      appBar: AppBar(title: const Text('Online Market')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final products = snap.data!;
          final grid = GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .75,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(
              product: products[i],
              onAdd: () => _addToCart(products[i]),
            ),
          );

          final cartSide = Container(
            width: 350,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sepet', style: Theme.of(context).textTheme.headline6),
                const Divider(),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Sepet boş'))
                      : ListView(
                          children: _cart.entries
                              .map((e) => CartItemTile(
                                    product: e.key,
                                    qty: e.value,
                                    onInc: () => _inc(e.key),
                                    onDec: () => _dec(e.key),
                                    onRemove: () => _remove(e.key),
                                  ))
                              .toList(),
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toplam:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_total.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                    onPressed: _showRecipe,
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('Tarif Öner')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    onPressed: _showAnalysis,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Besin Analizi')),
              ],
            ),
          );

          if (isWide) {
            return Row(children: [
              Expanded(child: grid),
              cartSide,
            ]);
          } else {
            // dar ekranda sepet alt kısımda
            return Column(children: [
              Expanded(child: grid),
              SizedBox(
                  height: 300,
                  child: Material(elevation: 4, child: cartSide)),
            ]);
          }
        },
      ),
    );
  }
}
