import 'package:flutter/material.dart';
import '../services/stock_service.dart';

class StockScreen extends StatefulWidget {
  final bool inPanel;
  const StockScreen({Key? key, this.inPanel = false}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<Map<String, dynamic>>> _futureStock;
  String selectedCategory = "all";

  final List<Map<String, String>> categories = [
    {"key": "all", "title": "Tüm Stoğum"},
    {"key": "meyve_sebze", "title": "Meyvelerim ve Sebzelerim"},
    {"key": "et_tavuk", "title": "Et ve Tavuk Ürünlerim"},
    {"key": "sut_urunleri", "title": "Süt Ürünlerim"},
    {"key": "icecekler", "title": "İçeceklerim"},
    {"key": "atistirmalik", "title": "Atıştırmalıklarım"},
    {"key": "temizlik", "title": "Temizlik Ürünlerim"},
  ];

  @override
  void initState() {
    super.initState();
    _futureStock = StockService.fetchUserStock();
  }

  Future<void> _deleteStockItem(String productId) async {
    try {
      await StockService.deleteStockItem(productId);
      setState(() {
        _futureStock = StockService.fetchUserStock();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün stoktan silindi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme işlemi başarısız: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filterStockItems(List<Map<String, dynamic>> items) {
    if (selectedCategory == "all") return items;
    return items.where((item) => (item['category'] ?? 'belirsiz') == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Theme.of(context).platform == TargetPlatform.macOS || Theme.of(context).platform == TargetPlatform.windows || Theme.of(context).platform == TargetPlatform.linux;
    final content = FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureStock,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        final stockItems = _filterStockItems(snapshot.data ?? []);
        if (stockItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, color: Colors.white24, size: 80),
                const SizedBox(height: 18),
                const Text('Stoğunuzda ürün yok.', style: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Ürün ekledikçe burada gözükecek.', style: TextStyle(color: Colors.white38, fontSize: 16)),
              ],
            ),
          );
        }
        // WEB PANEL TASARIMI
        if (isWeb || widget.inPanel) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.2,
              ),
              itemCount: stockItems.length,
              itemBuilder: (context, i) {
                final item = stockItems[i];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232323),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.13),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade800, width: 1),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item['image_url'] != null
                                ? Image.network(
                                    item['image_url'],
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 22),
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.inventory, color: Colors.white38, size: 22),
                                  ),
                          ),
                        ),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['name'] ?? item['product_id'] ?? '-',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (item['category'] ?? '').toString().replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Adet: ${item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFF2552C), size: 20),
                          onPressed: () => _deleteStockItem(item['product_id'] ?? item['id']),
                          tooltip: 'Sil',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        // MOBİL TAM EKRAN TASARIMI
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          itemCount: stockItems.length,
          separatorBuilder: (context, i) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final item = stockItems[i];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232323),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade800, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item['image_url'] != null
                      ? Image.network(
                          item['image_url'],
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey[900],
                            child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 22),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: Colors.grey[900],
                          child: const Icon(Icons.inventory, color: Colors.white38, size: 22),
                        ),
                ),
                title: Text(
                  item['name'] ?? item['product_id'] ?? '-',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    Text(
                      'Adet: ${item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (item['category'] ?? '').toString().replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFF2552C), size: 22),
                  onPressed: () => _deleteStockItem(item['product_id'] ?? item['id']),
                  tooltip: 'Sil',
                ),
              ),
            );
          },
        );
      },
    );

    // Kategori butonları için modern koyu tema görünüm
    final categoryBar = Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((category) {
            final isSelected = selectedCategory == category["key"];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepOrange : const Color(0xFF353535),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isSelected ? Colors.deepOrange : Colors.grey.shade700, width: 2),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.deepOrange.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 2))]
                      : [],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      selectedCategory = category["key"]!;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      category["title"]!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (widget.inPanel) {
      return Container(
        width: 420,
        padding: const EdgeInsets.all(0),
        color: const Color(0xFF232323),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 32, top: 24, bottom: 8),
                  child: Text('Stoğum', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            categoryBar,
            const SizedBox(height: 8),
            Expanded(child: content),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.psychology_alt, size: 24),
                label: const Text('Yardım Al'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF232323),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Text('Yapay zekadan destek al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HelpExpandable(
                              icon: '🍽️',
                              label: 'Akşam Yemeği Öner',
                              children: [
                                'Pratik (10–15 dk) tarif öner',
                                'Ortalama (30–45 dk) tarif öner',
                                'Uğraştırıcı (1 saat+) tarif öner',
                                'Etsiz tarif öner',
                                'Sulu yemek öner',
                                'Tek tavada yemek',
                              ],
                            ),
                            _HelpExpandable(
                              icon: '☕',
                              label: 'Kahvaltılık Tarif Öner',
                              children: [
                                'Pratik kahvaltı',
                                'Yumurtalı tarif',
                                'Ekmeksiz kahvaltı',
                                'Tatlı kahvaltılık',
                                'Hafif kahvaltı öner',
                                'Soğuk kahvaltı önerisi (yaz için)',
                              ],
                            ),
                            _HelpExpandable(
                              icon: '🍿',
                              label: 'Atıştırmalık Fikirleri',
                              children: [
                                'Tatlı atıştırmalık',
                                'Tuzlu atıştırmalık',
                                'Fırın/ocaksız tarif',
                                'Film/gece atıştırması',
                                'Diyet dostu atıştırmalık',
                                '5 dakikada hazırlanabilen',
                              ],
                            ),
                            _HelpExpandable(
                              icon: '🛒',
                              label: 'Alışveriş Listesi Tavsiyesi',
                              children: [
                                'Stoğuma göre eksikler neler?',
                                '3 gün yetecek alışveriş planı',
                                'Kahvaltılık eksiklerim',
                                'Temel ihtiyaç listesi',
                                'Protein ağırlıklı alışveriş',
                                'Haftalık "temiz beslenme" listesi',
                              ],
                            ),
                            _HelpExpandable(
                              icon: '🩺',
                              label: 'Stoğuma Göre Kişisel Sağlık',
                              children: [
                                'Stoğumun besin dengesi nasıl?',
                                'Karbonhidrat/protein oranı',
                                'Sebze ağırlıklı tarif öner',
                                'Düşük kalorili tarif öner',
                                'Bağışıklık güçlendirici öneri',
                                'Egzersiz sonrası yemek önerisi',
                                'Günlük kaloriye uygun tarif',
                                'Vitamin yönünden zengin içerik önerisi',
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF353535),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  elevation: 0,
                                ),
                                icon: const Text('✍️', style: TextStyle(fontSize: 22)),
                                label: const Text('Kendi Sorunu Sor'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpChatScreen()));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Kapat', style: TextStyle(color: Colors.deepOrange)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        title: const Text('Stoğum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          categoryBar,
          const SizedBox(height: 8),
          Expanded(child: content),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.psychology_alt, size: 24),
              label: const Text('Yardım Al'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF232323),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Yapay zekadan destek al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HelpExpandable(
                            icon: '🍽️',
                            label: 'Akşam Yemeği Öner',
                            children: [
                              'Pratik (10–15 dk) tarif öner',
                              'Ortalama (30–45 dk) tarif öner',
                              'Uğraştırıcı (1 saat+) tarif öner',
                              'Etsiz tarif öner',
                              'Sulu yemek öner',
                              'Tek tavada yemek',
                            ],
                          ),
                          _HelpExpandable(
                            icon: '☕',
                            label: 'Kahvaltılık Tarif Öner',
                            children: [
                              'Pratik kahvaltı',
                              'Yumurtalı tarif',
                              'Ekmeksiz kahvaltı',
                              'Tatlı kahvaltılık',
                              'Hafif kahvaltı öner',
                              'Soğuk kahvaltı önerisi (yaz için)',
                            ],
                          ),
                          _HelpExpandable(
                            icon: '🍿',
                            label: 'Atıştırmalık Fikirleri',
                            children: [
                              'Tatlı atıştırmalık',
                              'Tuzlu atıştırmalık',
                              'Fırın/ocaksız tarif',
                              'Film/gece atıştırması',
                              'Diyet dostu atıştırmalık',
                              '5 dakikada hazırlanabilen',
                            ],
                          ),
                          _HelpExpandable(
                            icon: '🛒',
                            label: 'Alışveriş Listesi Tavsiyesi',
                            children: [
                              'Stoğuma göre eksikler neler?',
                              '3 gün yetecek alışveriş planı',
                              'Kahvaltılık eksiklerim',
                              'Temel ihtiyaç listesi',
                              'Protein ağırlıklı alışveriş',
                              'Haftalık "temiz beslenme" listesi',
                            ],
                          ),
                          _HelpExpandable(
                            icon: '🩺',
                            label: 'Stoğuma Göre Kişisel Sağlık',
                            children: [
                              'Stoğumun besin dengesi nasıl?',
                              'Karbonhidrat/protein oranı',
                              'Sebze ağırlıklı tarif öner',
                              'Düşük kalorili tarif öner',
                              'Bağışıklık güçlendirici öneri',
                              'Egzersiz sonrası yemek önerisi',
                              'Günlük kaloriye uygun tarif',
                              'Vitamin yönünden zengin içerik önerisi',
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF353535),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                elevation: 0,
                              ),
                              icon: const Text('✍️', style: TextStyle(fontSize: 22)),
                              label: const Text('Kendi Sorunu Sor'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpChatScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kapat', style: TextStyle(color: Colors.deepOrange)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Yardım başlıkları için açılır/kapanır widget
class _HelpExpandable extends StatefulWidget {
  final String icon;
  final String label;
  final List<String> children;
  const _HelpExpandable({required this.icon, required this.label, required this.children});
  @override
  State<_HelpExpandable> createState() => _HelpExpandableState();
}
class _HelpExpandableState extends State<_HelpExpandable> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF353535),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          icon: Text(widget.icon, style: const TextStyle(fontSize: 22)),
          label: Text(widget.label),
          onPressed: () => setState(() => expanded = !expanded),
        ),
        if (expanded)
          ...widget.children.map((child) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF232323),
                    foregroundColor: Colors.white70,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: Align(alignment: Alignment.centerLeft, child: Text(child)),
                ),
              )),
      ],
    );
  }
}

// Kendi Sorunu Sor için chat ekranı (şimdilik boş)
class HelpChatScreen extends StatelessWidget {
  const HelpChatScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        title: const Text('Yapay Zeka Sohbet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text('Burada stoğunuzla ilgili sorularınızı yazabilirsiniz.', style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
    );
  }
} 