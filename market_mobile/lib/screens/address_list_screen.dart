import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddressListScreen extends StatefulWidget {
  final bool inPanel;
  const AddressListScreen({Key? key, this.inPanel = false}) : super(key: key);

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  String userUid = '';
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserUid();
    await _getToken();
    await _fetchAddresses();
  }

  Future<void> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        token = prefs.getString('token');
      });
      print('Token alındı: ${token?.substring(0, 10)}...');
    } catch (e) {
      print('Token alma hatası: $e');
    }
  }

  Future<void> _getUserUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userUid = prefs.getString('uid') ?? '';
    });
    print('UID alındı: $userUid');
  }

  Future<void> _fetchAddresses() async {
    if (token == null) {
      print('Token bulunamadı!');
      return;
    }

    setState(() { isLoading = true; });
    try {
      final result = await fetchAddressesFromApi(userUid);
      setState(() {
        addresses = result;
        isLoading = false;
      });
    } catch (e) {
      print('Adres getirme hatası: $e');
      setState(() { isLoading = false; });
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000'; // Android emülatör için
      // Gerçek cihazda test için: bilgisayarının IP adresini yazabilirsin
    }
  }

  Future<List<Map<String, dynamic>>> fetchAddressesFromApi(String uid) async {
    if (token == null) throw Exception('Token bulunamadı');
    final url = '${getBaseUrl()}/api/auth/users/$uid/addresses';
    print('Adres getirme isteği: $url');
    print('Token: [32m${token?.substring(0, 10)}...[0m');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token'
      }
    );
    print('API Yanıt Kodu: ${response.statusCode}');
    print('API Yanıtı: ${response.body}');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('API Hatası: ${response.body}');
      return [];
    }
  }

  Future<void> addAddressToApi(String uid, Map<String, dynamic> address) async {
    if (token == null) throw Exception('Token bulunamadı');
    final url = '${getBaseUrl()}/api/auth/users/$uid/addresses';
    print('Adres ekleme isteği: $url');
    print('Adres verisi: $address');
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(address),
    );
    print('API Yanıt Kodu: ${response.statusCode}');
    print('API Yanıtı: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Adres eklenemedi: ${response.body}');
    }
  }

  Future<void> deleteAddressFromApi(String uid, String addressId) async {
    if (token == null) throw Exception('Token bulunamadı');
    final url = '${getBaseUrl()}/api/auth/users/$uid/addresses/$addressId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token'
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Adres silinemedi: ${response.body}');
    }
  }

  void _showAddAddressDialog() async {
    String title = '';
    String mahalle = '';
    String sokak = '';
    String binaNo = '';
    String kat = '';
    String daireNo = '';
    String tarif = '';
    bool isDefault = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF232323),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Adres Ekle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Başlık (Ev, İş, vb)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF353535),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => title = v,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Mahalle/Sokak/Cadde',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF353535),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => mahalle = v,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Bina No',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Color(0xFF353535),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) => binaNo = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Kat',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Color(0xFF353535),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) => kat = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Daire No',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Color(0xFF353535),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) => daireNo = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Adres Tarifi',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF353535),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  onChanged: (v) => tarif = v,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: isDefault,
                      activeColor: Colors.deepOrange,
                      onChanged: (v) {
                        isDefault = v;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                    const Text('Varsayılan adres', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (title.trim().isEmpty || mahalle.trim().isEmpty || binaNo.trim().isEmpty) return;
                final address = {
                  'title': title,
                  'mahalle': mahalle,
                  'sokak': sokak,
                  'binaNo': binaNo,
                  'kat': kat,
                  'daireNo': daireNo,
                  'tarif': tarif,
                  'isDefault': isDefault
                };
                await addAddressToApi(userUid, address);
                Navigator.pop(context);
                await _fetchAddresses();
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _addAddress() {
    _showAddAddressDialog();
  }

  void _editAddress(int idx) {
    // Demo için basit düzenleme
    setState(() {
      addresses[idx]['address'] += ' (Düzenlendi)';
    });
  }

  void _deleteAddress(int idx) async {
    final addressId = addresses[idx]['id'] ?? addresses[idx]['_id'];
    try {
      await deleteAddressFromApi(userUid, addressId);
      setState(() {
        addresses.removeAt(idx);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adres silinemedi: $e')),
      );
    }
  }

  void _setDefault(int idx) {
    setState(() {
      for (var i = 0; i < addresses.length; i++) {
        addresses[i]['isDefault'] = i == idx;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? const Center(child: CircularProgressIndicator())
        : addresses.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adreslerim', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_location_alt, color: Colors.deepOrange),
                        onPressed: _addAddress,
                        tooltip: 'Adres Ekle',
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text('Henüz adres eklemediniz', style: TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Adreslerim', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_location_alt, color: Colors.deepOrange),
                        onPressed: _addAddress,
                        tooltip: 'Adres Ekle',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...addresses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final addr = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF353535),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(addr['isDefault'] ? Icons.home : Icons.location_on, color: Colors.white),
                        title: Text('${addr['title']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${addr['mahalle']} ${addr['sokak']} No:${addr['binaNo']} Kat:${addr['kat']} Daire:${addr['daireNo']}\n${addr['tarif']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!addr['isDefault'])
                              IconButton(
                                icon: const Icon(Icons.star_border, color: Colors.orange),
                                tooltip: 'Varsayılan yap',
                                onPressed: () => _setDefault(idx),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70),
                              tooltip: 'Düzenle',
                              onPressed: () => _editAddress(idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Sil',
                              onPressed: () => _deleteAddress(idx),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );

    if (widget.inPanel) {
      return Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF232323),
        child: SingleChildScrollView(child: content),
      );
    }
    // Mobilde tam ekran
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        title: const Text('Adreslerim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(child: content),
      ),
    );
  }
} 