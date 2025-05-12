import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class PaymentScreen extends StatefulWidget {
  final String address;
  final String? note;
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  const PaymentScreen({Key? key, required this.address, this.note, this.cartItems = const [
    {'name': 'Portakal', 'qty': 2, 'price': 35.0},
    {'name': 'Elma', 'qty': 1, 'price': 28.0},
  ], this.totalAmount = 98.0}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedPayment;
  bool saveCard = false;
  bool kvkkOk = false;
  bool contractOk = false;
  final _cardNoController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _invoiceController = TextEditingController();
  String _orderNote = '';

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final double maxWidth = isWeb ? 540 : 400;
    final double cardPadding = isWeb ? 32 : 18;
    final double fontSize = isWeb ? 22 : 18;
    final double buttonHeight = isWeb ? 56 : 48;

    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ödeme', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sipariş Özeti', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...widget.cartItems.map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['name']} x${item['qty']}', style: TextStyle(color: Colors.white70, fontSize: fontSize-2)),
                    Text('₺${(item['price'] * item['qty']).toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: fontSize-2)),
                  ],
                )),
                const Divider(color: Colors.white24, height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Toplam', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                    Text('₺${widget.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.orange, fontSize: fontSize, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Teslimat Adresi', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF353535),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(widget.address, style: TextStyle(color: Colors.white70, fontSize: fontSize-2)),
                ),
                const SizedBox(height: 18),
                Text('Sipariş Notu (isteğe bağlı)', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Siparişinizle ilgili not ekleyebilirsiniz...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF353535),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  style: TextStyle(color: Colors.white, fontSize: fontSize-2),
                  maxLines: 2,
                  onChanged: (val) => setState(() { _orderNote = val; }),
                ),
                const SizedBox(height: 18),
                Text('Ödeme Seçeneği', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildPaymentOption('Kapıda Ödeme', Icons.payments),
                const SizedBox(height: 14),
                _buildPaymentOption('Kredi Kartı', Icons.credit_card),
                const SizedBox(height: 18),
                if (selectedPayment == 'Kredi Kartı') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF353535),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Kart Bilgileri', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cardNoController,
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Kart Numarası',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF2E2E2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            counterText: '',
                          ),
                          style: TextStyle(color: Colors.white, fontSize: fontSize-2),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryController,
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                decoration: InputDecoration(
                                  labelText: 'AA/YY',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Color(0xFF2E2E2E),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  counterText: '',
                                ),
                                style: TextStyle(color: Colors.white, fontSize: fontSize-4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Color(0xFF2E2E2E),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  counterText: '',
                                ),
                                style: TextStyle(color: Colors.white, fontSize: fontSize-4),
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cardNameController,
                          decoration: InputDecoration(
                            labelText: 'Kart Üzerindeki İsim',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF2E2E2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          style: TextStyle(color: Colors.white, fontSize: fontSize-2),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: saveCard,
                              onChanged: (v) => setState(() => saveCard = v ?? false),
                              activeColor: Colors.deepOrange,
                            ),
                            const Text('Kartı kaydet', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text('Fatura Bilgisi (isteğe bağlı)', style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _invoiceController,
                  decoration: InputDecoration(
                    hintText: 'Fatura adresi veya firma bilgisi',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF353535),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  style: TextStyle(color: Colors.white, fontSize: fontSize-2),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Checkbox(
                      value: kvkkOk,
                      onChanged: (v) => setState(() => kvkkOk = v ?? false),
                      activeColor: Colors.deepOrange,
                    ),
                    Expanded(child: Text("KVKK Aydınlatma Metni'ni okudum, kabul ediyorum.", style: TextStyle(color: Colors.white70, fontSize: 14))),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: contractOk,
                      onChanged: (v) => setState(() => contractOk = v ?? false),
                      activeColor: Colors.deepOrange,
                    ),
                    Expanded(child: Text("Mesafeli Satış Sözleşmesi'ni okudum, kabul ediyorum.", style: TextStyle(color: Colors.white70, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 8),
                    const Text('Güvenli SSL ile ödeme', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.support_agent, color: Colors.blueAccent, size: 24),
                    const SizedBox(width: 6),
                    const Text('Destek: 0850 000 00 00', style: TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: (selectedPayment == null || !kvkkOk || !contractOk) ? null : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ödeme işlemi (demo)!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                      textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Ödemeyi Tamamla', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange.withOpacity(0.15) : const Color(0xFF353535),
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: Colors.deepOrange, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.deepOrange, size: 28),
          ],
        ),
      ),
    );
  }
} 