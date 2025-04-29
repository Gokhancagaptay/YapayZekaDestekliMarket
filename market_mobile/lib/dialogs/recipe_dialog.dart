class _RecipeDialog extends StatefulWidget {
  const _RecipeDialog();
  @override
  State<_RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends State<_RecipeDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _result;          // tarif
  Map<String, dynamic>? _analysis; // besin analizi

  Future<void> _runRequests() async {
    final ing = _controller.text.trim();
    if (ing.isEmpty) return;
    setState(() { _loading = true; _result = null; _analysis = null; });

    try {
      final suggestion = await ApiService.suggestRecipe(ing);
      final analysis   = await ApiService.analyzeNutrition(ing);
      setState(() {
        _result = suggestion;
        _analysis = analysis;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tarif Öner / Besin Analizi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Malzemeleri virgülle ayırarak yaz (örn: domates, yumurta)',
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) const CircularProgressIndicator(),
          if (_result != null) ...[
            const Divider(),
            Text('Önerilen Tarif', style: Theme.of(context).textTheme.titleMedium),
            Text(_result!, style: const TextStyle(fontSize: 14)),
          ],
          if (_analysis != null) ...[
            const Divider(),
            Text('Besin Analizi', style: Theme.of(context).textTheme.titleMedium),
            Text('Protein: ${_analysis!["analiz"]["protein"]} g'),
            Text('Karbonhidrat: ${_analysis!["analiz"]["karbonhidrat"]} g'),
            Text('Yağ: ${_analysis!["analiz"]["yağ"]} g'),
            const SizedBox(height: 4),
            Text(_analysis!["yorum"]),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        FilledButton(onPressed: _runRequests, child: const Text('Çalıştır')),
      ],
    );
  }
}
