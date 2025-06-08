import 'package:flutter/material.dart';
import '../services/stock_service.dart' show StockService;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analysis_service.dart';
import 'dart:convert';

class _ParsedAnalysisResult {
  final String displayText;
  final List<Map<String, dynamic>> ingredientsForOne;
  _ParsedAnalysisResult(this.displayText, this.ingredientsForOne);
}

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

  String? _editingItemId;
  final TextEditingController _quantityController = TextEditingController();
  int _currentEditingOriginalQuantity = 0;
  String? _quantityError;

  @override
  void initState() {
    super.initState();
    _futureStock = StockService.fetchUserStock();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _deleteStockItem(String productId) async {
    try {
      await StockService.deleteStockItem(productId);
      setState(() {
        _futureStock = StockService.fetchUserStock();
        _editingItemId = null;
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
  
  Future<void> _updateStockQuantity(Map<String, dynamic> stockItem, int newQuantity) async {
    final productId = stockItem['product_id'] as String? ?? stockItem['id'] as String? ?? '';
    if (productId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('''Güncellenecek ürün ID'si bulunamadı.''')),
        );
        return;
    }

    try {
      if (newQuantity <= 0) {
        await _deleteStockItem(productId);
      } else {
        await StockService.updateStockItemQuantity(
          productId,
          newQuantity.toDouble(),
          stockItem,
        );
        setState(() {
          _futureStock = StockService.fetchUserStock();
          _editingItemId = null;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${stockItem['name']} stoğu $newQuantity olarak güncellendi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok güncelleme işlemi başarısız: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filterStockItems(List<Map<String, dynamic>> items) {
    if (selectedCategory == "all") return items;
    return items.where((item) => (item['category'] ?? 'belirsiz') == selectedCategory).toList();
  }

  Future<void> _handleSnackSuggestion(String label) async {
    String? snackType;
    if (label.contains('Tatlı')) snackType = 'sweet';
    else if (label.contains('Tuzlu')) snackType = 'salty';
    else if (label.contains('Fırın/Ocaksız')) snackType = 'no_cooking';
    else if (label.contains('Film/Gece')) snackType = 'movie_night';
    else if (label.contains('Diyet Dostu')) snackType = 'diet_friendly';
    else if (label.contains('5 Dakika')) snackType = 'quick';
    if (snackType == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final suggestion = await AnalysisService.snackSuggestion(
        userId: '',
        snackType: snackType,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(suggestion, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleShoppingSuggestion(String label) async {
    String? listType;
    if (label.contains('Stoğuma Göre Eksikler')) listType = 'basic_needs';
    else if (label.contains('3 Gün')) listType = 'three_day_plan';
    else if (label.contains('Kahvaltılık')) listType = 'breakfast_essentials';
    else if (label.contains('Temel İhtiyaç')) listType = 'essential_items';
    else if (label.contains('Protein')) listType = 'protein_focused';
    else if (label.contains('Temiz Beslenme')) listType = 'clean_eating';
    if (listType == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final suggestion = await AnalysisService.shoppingSuggestion(
        userId: '',
        listType: listType,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(suggestion, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleNutritionAnalysis(String label) async {
    String? analysisType;
    if (label.contains('Besin Dengesi')) analysisType = 'balance';
    else if (label.contains('Karbonhidrat/Protein')) analysisType = 'carb_protein';
    else if (label.contains('Sebze Ağırlıklı')) analysisType = 'veggie_recipe';
    else if (label.contains('Düşük Kalorili')) analysisType = 'low_calorie';
    else if (label.contains('Bağışıklık')) analysisType = 'immune_boost';
    else if (label.contains('Egzersiz Sonrası')) analysisType = 'post_workout';
    else if (label.contains('Günlük Kalori')) analysisType = 'calorie_specific';
    else if (label.contains('Vitamin')) analysisType = 'vitamin_rich';
    if (analysisType == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rawAnalysis = await AnalysisService.nutritionAnalysis(
        userId: '',
        analysisType: analysisType,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      final parsedResult = _parseAnalysisResponse(rawAnalysis);
      final String analysisText = parsedResult.displayText;
      final List<Map<String, dynamic>> ingredients = parsedResult.ingredientsForOne;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(analysisText, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showRecipeMadeDialog(context, label, ingredients.isNotEmpty ? ingredients : null);
              },
              child: const Text('Bu tarifi yaptım', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.deepOrangeAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleDinnerSuggestion(String label) async {
    String? suggestionType;
    if (label.contains('Pratik (10–15 dk)')) suggestionType = 'quick';
    else if (label.contains('Ortalama (30–45 dk)')) suggestionType = 'medium';
    else if (label.contains('Uğraştırıcı (1 saat+)')) suggestionType = 'long';
    else if (label.contains('Etsiz')) suggestionType = 'meatless';
    else if (label.contains('Sulu yemek')) suggestionType = 'soupy';
    else if (label.contains('Tek tavada')) suggestionType = 'onepan';
    if (suggestionType == null) {
      print("Geçersiz akşam yemeği öneri tipi etiketi: $label");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rawSuggestion = await AnalysisService.dinnerSuggestion(
        userId: '',
        suggestionType: suggestionType,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      final parsedResult = _parseAnalysisResponse(rawSuggestion);
      final String suggestionText = parsedResult.displayText;
      final List<Map<String, dynamic>> ingredients = parsedResult.ingredientsForOne;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(suggestionText, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showRecipeMadeDialog(context, label, ingredients.isNotEmpty ? ingredients : null);
              },
              child: const Text('Bu tarifi yaptım', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.deepOrangeAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleBreakfastSuggestion(String label) async {
    String? recipeType;
    if (label.contains('Pratik kahvaltı')) recipeType = 'quick';
    else if (label.contains('Yumurtalı')) recipeType = 'eggy';
    else if (label.contains('Ekmeksiz')) recipeType = 'breadless';
    else if (label.contains('Tatlı')) recipeType = 'sweet';
    else if (label.contains('Hafif')) recipeType = 'light';
    else if (label.contains('Soğuk')) recipeType = 'cold';
    if (recipeType == null) {
      print("Geçersiz kahvaltı öneri tipi etiketi: $label");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rawSuggestion = await AnalysisService.breakfastSuggestion(
        userId: '',
        recipeType: recipeType,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      final parsedResult = _parseAnalysisResponse(rawSuggestion);
      final String suggestionText = parsedResult.displayText;
      final List<Map<String, dynamic>> ingredients = parsedResult.ingredientsForOne;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(suggestionText, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showRecipeMadeDialog(context, label, ingredients.isNotEmpty ? ingredients : null);
              },
              child: const Text('Bu tarifi yaptım', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat', style: TextStyle(color: Colors.deepOrangeAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

  Future<void> _showRecipeMadeDialog(
    BuildContext dialogContext, 
    String recipeName,
    List<Map<String, dynamic>>? ingredientsForOne,
  ) async {
    final TextEditingController servingsController = TextEditingController();
    return showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext alertContext) {
        return AlertDialog(
          title: Text('$recipeName Tarifini Yaptınız Mı?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Bu tarifi kaç kişilik hazırladınız?'),
                const SizedBox(height: 16),
                TextField(
                  controller: servingsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Porsiyon Sayısı',
                    hintText: 'Örn: 4',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(alertContext).pop();
              },
            ),
            TextButton(
              child: const Text('Stoktan Sil'),
              onPressed: () async {
                final String servingsText = servingsController.text;
                final int? servings = int.tryParse(servingsText);

                if (servings != null && servings > 0) {
                  Navigator.of(alertContext).pop();
                  
                  if (ingredientsForOne != null && ingredientsForOne.isNotEmpty) {
                    print("[LOG] Recipe: $recipeName, Servings: $servings. Processing ${ingredientsForOne.length} ingredients for stock deduction.");
                    try {
                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );

                      final List<Map<String, dynamic>> currentStockItems = await StockService.fetchUserStock();
                      print("[LOG] Fetched ${currentStockItems.length} items from current stock.");
                      bool anItemWasUpdated = false;

                      for (var ingredient in ingredientsForOne) {
                        final String? productId = ingredient['product_id']?.toString();
                        final String? productName = ingredient['name']?.toString() ?? "Bilinmeyen Ürün";
                        final num? quantityOneServing = ingredient['quantity'] as num?;

                        print("[LOG] Processing ingredient: $productName (ID: $productId), Quantity for 1 serving: $quantityOneServing");

                        if (productId == null || quantityOneServing == null) {
                          print("[LOG] Skipping ingredient $productName (ID: $productId) due to missing product_id or quantity_one_serving.");
                          continue;
                        }

                        final Map<String, dynamic>? stockItem = currentStockItems.firstWhere(
                          (item) => (item['product_id']?.toString() ?? item['id']?.toString() ?? '') == productId,
                          orElse: () {
                            print("[LOG] Ingredient $productName (ID: $productId) NOT FOUND in current stock via firstWhere.");
                            return <String,dynamic>{};
                          },
                        );

                        if (stockItem == null || stockItem.isEmpty) { 
                          print("[LOG] Ingredient $productName (ID: $productId) was not found in stock or stockItem map is empty. Cannot decrement.");
                          continue; 
                        }
                        
                        final num currentQuantityNum = stockItem['quantity'] as num? ?? 0;
                        final double quantityToDecrement = quantityOneServing.toDouble() * servings;
                        final int newQuantityInt = (currentQuantityNum.toDouble() - quantityToDecrement).round();

                        print("[LOG] Stock item found: $productName (ID: $productId). Current quantity: $currentQuantityNum. Quantity to decrement for $servings servings: $quantityToDecrement. New calculated quantity: $newQuantityInt");

                        if (newQuantityInt == currentQuantityNum.toInt()) {
                            print("[LOG] Quantity for $productName (ID: $productId) will not change ($newQuantityInt). Skipping update to avoid unnecessary API call.");
                        } else {
                            print("[LOG] Calling _updateStockQuantity for $productName (ID: $productId) with new quantity: $newQuantityInt");
                            await _updateStockQuantity(stockItem, newQuantityInt);
                            anItemWasUpdated = true;
                            print("[LOG] _updateStockQuantity finished for $productName (ID: $productId).");
                        }
                      }
                       if (mounted) Navigator.of(dialogContext).pop();
                      print("[LOG] Stock deduction loop finished. anItemWasUpdated: $anItemWasUpdated");

                      if(anItemWasUpdated){
                         ScaffoldMessenger.of(dialogContext).showSnackBar(
                           SnackBar(content: Text('$recipeName tarifi için $servings kişilik malzemeler stoktan düşüldü (eğer stokta varsa).')),
                         );
                      } else if (ingredientsForOne.isNotEmpty) {
                         ScaffoldMessenger.of(dialogContext).showSnackBar(
                           SnackBar(content: Text('$recipeName için belirtilen malzemelerden hiçbiri stoğunuzda bulunamadı veya güncellenmesi gerekmedi.')),
                         );
                      } else {
                         print('[LOG] User made $recipeName for $servings servings. (No ingredient list provided for stock deduction)');
                         ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('$recipeName tarifi için $servings kişilik bilgi kaydedildi (malzemesiz).')),
                         );
                      }

                    } catch (e) {
                       print("[LOG_ERROR] Error during stock deduction for recipe $recipeName: $e");
                       if (mounted) Navigator.of(dialogContext).pop();
                       ScaffoldMessenger.of(dialogContext).showSnackBar(
                         SnackBar(content: Text('Stok güncelleme sırasında bir hata oluştu: $e')),
                       );
                    }
                  } else {
                     print('[LOG] User made $recipeName for $servings servings. (Ingredient list was null or empty, no stock deduction attempted)');
                     ScaffoldMessenger.of(dialogContext).showSnackBar(
                       SnackBar(content: Text('$recipeName tarifi için $servings kişilik bilgi kaydedildi (malzemesiz).')),
                     );
                  }
                } else {
                  print("[LOG_WARN] Invalid servings input: $servingsText");
                  ScaffoldMessenger.of(alertContext).showSnackBar(
                    const SnackBar(content: Text('Lütfen geçerli bir porsiyon sayısı girin.'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  _ParsedAnalysisResult _parseAnalysisResponse(String rawResponse) {
    const String startTag = "[MALZEMELER_JSON_START]";
    const String endTag = "[MALZEMELER_JSON_END]";

    final int startIndex = rawResponse.indexOf(startTag);
    final int endIndex = rawResponse.indexOf(endTag, startIndex + startTag.length);

    if (startIndex != -1 && endIndex != -1) {
      final String jsonString = rawResponse.substring(startIndex + startTag.length, endIndex);
      String displayText = rawResponse.substring(0, startIndex).trim() + 
                           (rawResponse.length > endIndex + endTag.length ? rawResponse.substring(endIndex + endTag.length).trim() : "");
      try {
        final decodedJson = json.decode(jsonString);
        if (decodedJson is Map && decodedJson.containsKey('ingredients_for_one')) {
          final List<dynamic> ingredientsRaw = decodedJson['ingredients_for_one'];
          final List<Map<String, dynamic>> ingredients = ingredientsRaw
              .whereType<Map<String, dynamic>>()
              .toList();
          return _ParsedAnalysisResult(displayText.isEmpty ? "Tarif detayı:" : displayText, ingredients);
        }
      } catch (e) {
        print("Error parsing ingredients JSON: $e. Raw JSON string: $jsonString");
      }
    }
    return _ParsedAnalysisResult(rawResponse, []);
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
        
        Widget buildStockItemCard(Map<String, dynamic> item, bool isWebLayout) {
          final String itemId = item['product_id'] as String? ?? item['id'] as String? ?? '';
          final bool isEditing = _editingItemId == itemId;
          final num? quantityNum = item['quantity'] as num?;
          final int currentQuantity = quantityNum?.toInt() ?? 0;

          Widget quantityDisplay;
          Widget actionControl;

          if (isEditing) {
            quantityDisplay = SizedBox(
              width: isWebLayout ? 40 : 36,
              height: 30,
              child: TextFormField(
                controller: _quantityController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                  errorText: _quantityError,
                  errorStyle: const TextStyle(fontSize: 0.01, color: Colors.transparent),
                ),
                onChanged: (value) {
                  final val = int.tryParse(value);
                  if (val == null || val < 0) {
                    setState(() => _quantityError = "Geçersiz");
                  } else {
                     setState(() => _quantityError = null);
                  }
                },
              ),
            );

            actionControl = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Azalt',
                  onPressed: () {
                    int currentVal = int.tryParse(_quantityController.text) ?? _currentEditingOriginalQuantity;
                    if (currentVal > 0) {
                      _quantityController.text = (currentVal - 1).toString();
                    }
                  },
                ),
                quantityDisplay,
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Artır',
                  onPressed: () {
                    int currentVal = int.tryParse(_quantityController.text) ?? _currentEditingOriginalQuantity;
                     _quantityController.text = (currentVal + 1).toString();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  padding: const EdgeInsets.only(left: 2, right: 1),
                  constraints: const BoxConstraints(),
                  tooltip: 'Onayla',
                  onPressed: () {
                    final int? newQuantity = int.tryParse(_quantityController.text);
                    if (newQuantity == null || newQuantity < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen geçerli bir miktar girin.')),
                      );
                      return;
                    }
                    if (newQuantity == _currentEditingOriginalQuantity) {
                       setState(() => _editingItemId = null);
                       return;
                    }
                    _updateStockQuantity(item, newQuantity);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                  padding: const EdgeInsets.only(left: 1),
                  constraints: const BoxConstraints(),
                  tooltip: 'İptal',
                  onPressed: () {
                    setState(() {
                      _editingItemId = null;
                       _quantityError = null;
                    });
                  },
                ),
              ],
            );
          } else {
            quantityDisplay = Text(
              'Adet: ${item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
            actionControl = IconButton(
              icon: const Icon(Icons.edit_note, color: Color(0xFFF2552C), size: 20),
              tooltip: 'Miktarı Düzenle/Sil',
              onPressed: () {
                setState(() {
                  _editingItemId = itemId;
                  _currentEditingOriginalQuantity = currentQuantity;
                  _quantityController.text = currentQuantity.toString();
                  _quantityError = null;
                });
              },
            );
          }

          if (isWebLayout) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: const Color(0xFF232323),
                      borderRadius: BorderRadius.circular(18),
                  boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.13), blurRadius: 12, offset: const Offset(0, 4), ), ],
                      border: Border.all(color: Colors.grey.shade800, width: 1),
                    ),
                    child: Row(
                      children: [
                        Padding(
                      padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                            child: item['image_url'] != null
                            ? Image.network( item['image_url'], width: 40, height: 40, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container( width: 40, height: 40, color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 20), ), )
                            : Container( width: 40, height: 40, color: Colors.grey[900], child: const Icon(Icons.inventory, color: Colors.white38, size: 20), ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            Text( item['name'] ?? item['product_id'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.1), maxLines: 1, overflow: TextOverflow.ellipsis, ),
                            if (!isEditing) ...[
                              const SizedBox(height: 4),
                              quantityDisplay, 
                            ]
                            ],
                          ),
                        ),
                        ),
                    Padding( 
                      padding: const EdgeInsets.only(right: 4.0),
                      child: actionControl,
                    )
                      ],
                    ),
            ),
          );
        }

            return Container(
              decoration: BoxDecoration(
              color: const Color(0xFF232323), borderRadius: BorderRadius.circular(18),
              boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.13), blurRadius: 12, offset: const Offset(0, 4), ), ],
                border: Border.all(color: Colors.grey.shade800, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item['image_url'] != null
                    ? Image.network( item['image_url'], width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container( width: 44, height: 44, color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 22), ), )
                    : Container( width: 44, height: 44, color: Colors.grey[900], child: const Icon(Icons.inventory, color: Colors.white38, size: 22), ),
              ),
              title: Text( item['name'] ?? item['product_id'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.1), maxLines: 1, overflow: TextOverflow.ellipsis, ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                  if (!isEditing) quantityDisplay,
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration( color: Colors.deepOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(12), ),
                      child: Text( (item['category'] ?? '').toString().replaceAll('_', ' '), style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.bold), ),
                    ),
                  ],
                ),
              trailing: actionControl,
            ),
          );
        }

        if (isWeb || widget.inPanel) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.9,
              ),
              itemCount: stockItems.length,
              itemBuilder: (context, i) {
                return buildStockItemCard(stockItems[i], true);
              },
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          itemCount: stockItems.length,
          separatorBuilder: (context, i) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            return buildStockItemCard(stockItems[i], false);
          },
        );
      },
    );

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
                    builder: (dialogBuilderContext) => AlertDialog(
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
                              onPressed: _handleDinnerSuggestion,
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
                              onPressed: _handleBreakfastSuggestion,
                            ),
                            _HelpExpandable(
                              icon: '🍿',
                              label: 'Atıştırmalık Fikirleri',
                              children: [
                                'Tatlı Atıştırmalık',
                                'Tuzlu Atıştırmalık',
                                'Fırın/Ocaksız Tarif',
                                'Film/Gece Atıştırması',
                                'Diyet Dostu Atıştırmalık',
                                '5 Dakikada Hazırlanabilen',
                              ],
                              onPressed: _handleSnackSuggestion,
                            ),
                            _HelpExpandable(
                              icon: '🛒',
                              label: 'Alışveriş Listesi Tavsiyesi',
                              children: [
                                'Stoğuma Göre Eksikler',
                                '3 Gün Yetecek Plan',
                                'Kahvaltılık Eksikler',
                                'Temel İhtiyaç Listesi',
                                'Protein Ağırlıklı Alışveriş',
                                'Haftalık "Temiz Beslenme" Listesi',
                              ],
                              onPressed: _handleShoppingSuggestion,
                            ),
                            _HelpExpandable(
                              icon: '🩺',
                              label: 'Stoğuma Göre Kişisel Sağlık',
                              children: [
                                'Stoğumun Besin Dengesi',
                                'Karbonhidrat/Protein Oranı',
                                'Sebze Ağırlıklı Tarif',
                                'Düşük Kalorili Tarif',
                                'Bağışıklık Güçlendirici',
                                'Egzersiz Sonrası Yemek',
                                'Günlük Kaloriye Uygun',
                                'Vitamin Açısından Zengin',
                              ],
                              onPressed: _handleNutritionAnalysis,
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
                                  Navigator.of(dialogBuilderContext).pop();
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpChatScreen()));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogBuilderContext).pop(),
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
                  builder: (dialogBuilderContext) => AlertDialog(
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
                            onPressed: _handleDinnerSuggestion,
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
                            onPressed: _handleBreakfastSuggestion,
                          ),
                          _HelpExpandable(
                            icon: '🍿',
                            label: 'Atıştırmalık Fikirleri',
                            children: [
                              'Tatlı Atıştırmalık',
                              'Tuzlu Atıştırmalık',
                              'Fırın/Ocaksız Tarif',
                              'Film/Gece Atıştırması',
                              'Diyet Dostu Atıştırmalık',
                              '5 Dakikada Hazırlanabilen',
                            ],
                            onPressed: _handleSnackSuggestion,
                          ),
                          _HelpExpandable(
                            icon: '🛒',
                            label: 'Alışveriş Listesi Tavsiyesi',
                            children: [
                              'Stoğuma Göre Eksikler',
                              '3 Gün Yetecek Plan',
                              'Kahvaltılık Eksikler',
                              'Temel İhtiyaç Listesi',
                              'Protein Ağırlıklı Alışveriş',
                              'Haftalık "Temiz Beslenme" Listesi',
                            ],
                            onPressed: _handleShoppingSuggestion,
                          ),
                          _HelpExpandable(
                            icon: '🩺',
                            label: 'Stoğuma Göre Kişisel Sağlık',
                            children: [
                              'Stoğumun Besin Dengesi',
                              'Karbonhidrat/Protein Oranı',
                              'Sebze Ağırlıklı Tarif',
                              'Düşük Kalorili Tarif',
                              'Bağışıklık Güçlendirici',
                              'Egzersiz Sonrası Yemek',
                              'Günlük Kaloriye Uygun',
                              'Vitamin Açısından Zengin',
                            ],
                            onPressed: _handleNutritionAnalysis,
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
                                Navigator.of(dialogBuilderContext).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpChatScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogBuilderContext).pop(),
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

class _HelpExpandable extends StatefulWidget {
  final String icon;
  final String label;
  final List<String> children;
  final Function(String) onPressed;
  const _HelpExpandable({required this.icon, required this.label, required this.children, required this.onPressed});
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
                  onPressed: () {
                    widget.onPressed(child);
                  },
                  child: Align(alignment: Alignment.centerLeft, child: Text(child)),
                ),
              )),
      ],
    );
  }
}

class HelpChatScreen extends StatefulWidget {
  const HelpChatScreen({Key? key}) : super(key: key);

  @override
  State<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends State<HelpChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isBotReplying = false;

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add({"type": "user", "text": messageText});
      _isBotReplying = true;
    });
    _messageController.clear();
          _scrollToBottom();

    try {
      final stockItems = await StockService.fetchUserStock();
      final List<String> ingredientNames = stockItems.map((item) => item['name'].toString()).toList();
      
      final botResponse = await AnalysisService.customQuestion(ingredientNames, messageText);
      
      setState(() {
        _messages.add({"type": "bot", "text": botResponse});
      });
    } catch (e) {
      setState(() {
        _messages.add({"type": "bot", "text": "Üzgünüm, bir hata oluştu: $e"});
      });
      print("HelpChatScreen sendMessage error: $e");
    } finally {
      setState(() {
        _isBotReplying = false;
      });
    _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

 @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Yapay Zeka Destek',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isBotReplying
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_answer_outlined, color: Colors.white38, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Stoğunuzla ilgili sorularınızı\nburaya yazabilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length + (_isBotReplying ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isBotReplying && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                          ),
                        );
                      }
                      final message = _messages[index];
                      final bool isUserMessage = message['type'] == 'user';
                      return Align(
                        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.deepOrange : const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            message['text']!,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      filled: true,
                      fillColor: const Color(0xFF3A3A3A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                Material(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(25.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25.0),
                    onTap: _sendMessage,
                    child: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Icon(Icons.send, color: Colors.white, size: 24),
                    ),
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