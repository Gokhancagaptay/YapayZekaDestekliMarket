import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/analysis_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    int totalItems = cart.items.values.fold<double>(0, (sum, item) => sum + (item.quantity ?? 1)).toInt();
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        title: const Text(
          'Sepet',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 32),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF7F2D),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cart.items.length.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      'Sepetiniz boş',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                item.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '₺${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  if (item.stock != null && item.stock! < 5)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Stokta ${item.stock}',
                                        style: TextStyle(color: Color(0xFF6FCF97), fontSize: 14),
                                      ),
                                    ),
                                  if (item.label != null)
                                    Container(
                                      margin: EdgeInsets.only(top: 4),
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF6FCF97).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.ac_unit, color: Color(0xFF6FCF97), size: 14),
                                          SizedBox(width: 4),
                                          Text(item.label!, style: TextStyle(color: Color(0xFF6FCF97), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF232323),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      cart.removeSingleItem(item.id);
                                    },
                                  ),
                                  Container(
                                    width: 36,
                                    alignment: Alignment.center,
                                    child: Text(
                                      item.quantity.toStringAsFixed(1),
                                      style: TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add, color: Colors.white),
                                    onPressed: () {
                                      cart.addItem(
                                        item.id,
                                        item.name,
                                        item.price,
                                        item.imageUrl,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Color(0xFF232323),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toplam Tutar', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text('₺${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Ürün Adedi', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text('$totalItems', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.analytics, color: Colors.white),
                      label: Text('Analiz Et', style: TextStyle(color: Colors.white, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6FCF97),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        final items = cart.items.values.map((item) => item.name).toList();
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            backgroundColor: Color(0xFF2C2C2E),
                            title: Text('Ne yapmak istersiniz?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            children: [
                              SimpleDialogOption(
                                child: Text('🍝 Ne yemek yapabilirim?', style: TextStyle(color: Colors.white)),
                                onPressed: () => Navigator.pop(context, 'suggest'),
                              ),
                              SimpleDialogOption(
                                child: Text('🍏 Sağlıklı mı?', style: TextStyle(color: Colors.white)),
                                onPressed: () => Navigator.pop(context, 'analyze'),
                              ),
                              SimpleDialogOption(
                                child: Text('💰 Fiyat analizi', style: TextStyle(color: Colors.white)),
                                onPressed: () => Navigator.pop(context, 'price'),
                              ),
                              SimpleDialogOption(
                                child: Text('🧠 Kendi sorumu yazacağım', style: TextStyle(color: Colors.white)),
                                onPressed: () => Navigator.pop(context, 'custom'),
                              ),
                            ],
                          ),
                        );
                        if (result == null) return;
                        String dialogTitle = '';
                        String dialogContent = '';
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('token');
                          if (result == 'suggest') {
                            dialogTitle = 'Yemek Önerisi';
                            dialogContent = await AnalysisService.suggestRecipe(items, token: token);
                          } else if (result == 'analyze') {
                            dialogTitle = 'Besin Analizi';
                            dialogContent = await AnalysisService.analyzeCartItems(items, token: token);
                          } else if (result == 'price') {
                            dialogTitle = 'Fiyat Analizi';
                            dialogContent = await AnalysisService.priceAnalysis(items);
                          } else if (result == 'custom') {
                            final TextEditingController customQuestionController = TextEditingController();
                            final customQ = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Color(0xFF2C2C2E),
                                title: Text('Sorunuzu yazın', style: TextStyle(color: Colors.white)),
                                content: TextField(
                                  controller: customQuestionController,
                                  autofocus: true,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(hintText: 'Sorunuz...', hintStyle: TextStyle(color: Colors.white54)),
                                  onSubmitted: (val) => Navigator.pop(context, val),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, null),
                                    child: Text('İptal', style: TextStyle(color: Color(0xFF6FCF97))),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, customQuestionController.text);
                                    },
                                    child: Text('Sor', style: TextStyle(color: Color(0xFF6FCF97))),
                                  ),
                                ],
                              ),
                            );
                            if (customQ == null || customQ.trim().isEmpty) return;
                            dialogTitle = 'Cevap';
                            dialogContent = await AnalysisService.customQuestion(items, customQ);
                          }
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Color(0xFF2C2C2E),
                              title: Text(dialogTitle, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              content: SingleChildScrollView(
                                child: MarkdownBody(
                                  data: dialogContent,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: TextStyle(color: Colors.white, fontSize: 16),
                                    h2: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Kapat', style: TextStyle(color: Color(0xFF6FCF97), fontSize: 16)),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('İşlem sırasında bir hata oluştu: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF7F2D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              address: "Ev adresim, İstanbul",
                            ),
                          ),
                        );
                      },
                      child: Text('Satın Al', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}