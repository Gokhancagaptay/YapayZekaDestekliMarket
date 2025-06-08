import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase/firebase_web_stub.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔄 Firebase\'den kullanıcılar yükleniyor');
      
      if (!kIsWeb) {
        // Real Firebase for Native platforms
        final databaseRef = FirebaseDatabase.instance.ref('users');
        final snapshot = await databaseRef.get();
        
        if (snapshot.exists) {
          final usersData = snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> usersList = [];
          
          usersData.forEach((key, value) {
            final userData = value as Map<dynamic, dynamic>;
            usersList.add({
              'id': key,
              'name': userData['displayName'] ?? 'İsimsiz Kullanıcı',
              'email': userData['email'] ?? 'Email Yok',
              'role': userData['role'] ?? 'Kullanıcı',
              'status': userData['status'] ?? 'Aktif',
            });
          });
          
          setState(() {
            _users = usersList;
            _isLoading = false;
          });
          print('✅ ${_users.length} adet kullanıcı Firebase\'den yüklendi');
        } else {
          print('ℹ️ Firebase\'de kullanıcı verisi bulunamadı');
          _loadDemoUsers();
        }
      } else {
        print('ℹ️ Web platformunda Firebase simülasyonu kullanılıyor');
        _loadDemoUsers();
      }
    } catch (e) {
      print('❌ Firebase kullanıcı verisi yüklenirken hata: $e');
      setState(() {
        _errorMessage = 'Kullanıcı verisi yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
      _loadDemoUsers();
    }
  }

  void _loadDemoUsers() {
    print('⚠️ Demo kullanıcı verileri yükleniyor');
    setState(() {
      _users = [
        {
          'id': '1',
          'name': 'Ahmet Yılmaz',
          'email': 'ahmet@example.com',
          'role': 'Admin',
          'status': 'Aktif',
        },
        {
          'id': '2',
          'name': 'Mehmet Demir',
          'email': 'mehmet@example.com',
          'role': 'Kullanıcı',
          'status': 'Aktif',
        },
        {
          'id': '3',
          'name': 'Ayşe Öztürk',
          'email': 'ayse@example.com',
          'role': 'Kullanıcı',
          'status': 'Beklemede',
        },
        {
          'id': '4',
          'name': 'Fatma Kaya',
          'email': 'fatma@example.com',
          'role': 'Kullanıcı',
          'status': 'Pasif',
        },
      ];
      _isLoading = false;
    });
  }

  // Firebase'de kullanıcı eklemek için fonksiyon
  Future<void> _addUser(Map<String, dynamic> user) async {
    try {
      print('🔄 Kullanıcı ekleniyor: ${user['email']}');
      
      if (!kIsWeb) {
        // Gerçek Firebase ile kullanıcı ekleme
        final userRef = FirebaseDatabase.instance.ref('users').push();
        await userRef.set({
          'displayName': user['name'],
          'email': user['email'],
          'role': user['role'],
          'status': user['status'],
          'createdAt': DateTime.now().toIso8601String(),
        });
        print('✅ Kullanıcı Firebase\'e başarıyla eklendi');
      } else {
        print('ℹ️ Web platformunda demo kullanıcı ekleniyor');
        // Demo kullanıcı ekle
        setState(() {
          user['id'] = DateTime.now().millisecondsSinceEpoch.toString();
          _users.add(user);
        });
      }
    } catch (e) {
      print('❌ Kullanıcı eklenirken hata: $e');
      throw e;
    }
  }

  // Firebase'de kullanıcı güncellemek için fonksiyon
  Future<void> _updateUser(String id, Map<String, dynamic> user) async {
    try {
      print('🔄 Kullanıcı güncelleniyor: $id');
      
      if (!kIsWeb) {
        // Gerçek Firebase ile kullanıcı güncelleme
        final userRef = FirebaseDatabase.instance.ref('users/$id');
        await userRef.update({
          'displayName': user['name'],
          'email': user['email'],
          'role': user['role'],
          'status': user['status'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
        print('✅ Kullanıcı Firebase\'de başarıyla güncellendi');
      } else {
        print('ℹ️ Web platformunda demo kullanıcı güncelleniyor');
        // Demo kullanıcı güncelle
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == id);
          if (index != -1) {
            _users[index] = {...user, 'id': id};
          }
        });
      }
    } catch (e) {
      print('❌ Kullanıcı güncellenirken hata: $e');
      throw e;
    }
  }

  // Firebase'de kullanıcı silmek için fonksiyon
  Future<void> _deleteUser(String id) async {
    try {
      print('🔄 Kullanıcı siliniyor: $id');
      
      if (!kIsWeb) {
        // Gerçek Firebase ile kullanıcı silme
        final userRef = FirebaseDatabase.instance.ref('users/$id');
        await userRef.remove();
        print('✅ Kullanıcı Firebase\'den başarıyla silindi');
      } else {
        print('ℹ️ Web platformunda demo kullanıcı siliniyor');
        // Demo kullanıcı sil
        setState(() {
          _users.removeWhere((u) => u['id'] == id);
        });
      }
    } catch (e) {
      print('❌ Kullanıcı silinirken hata: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kullanıcı Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddUserDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Kullanıcı'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchUsers,
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUsersTable(_users, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Kullanıcı ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          hint: const Text('Filtrele'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tümü')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
            DropdownMenuItem(value: 'active', child: Text('Aktif')),
            DropdownMenuItem(value: 'inactive', child: Text('Pasif')),
          ],
          onChanged: (value) {
            // Filtreleme işlemi
          },
        ),
      ],
    );
  }

  Widget _buildUsersTable(List<Map<String, dynamic>> users, BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Ad Soyad')),
              DataColumn(label: Text('E-posta')),
              DataColumn(label: Text('Rol')),
              DataColumn(label: Text('Durum')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: users.map((user) {
              return DataRow(cells: [
                DataCell(Text(user['name']!)),
                DataCell(Text(user['email']!)),
                DataCell(Text(user['role']!)),
                DataCell(_buildStatusBadge(user['status']!)),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showEditUserDialog(context, user);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        _showDeleteDialog(context, user);
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    
    switch (status) {
      case 'Aktif':
        color = Colors.green;
        break;
      case 'Pasif':
        color = Colors.red;
        break;
      case 'Beklemede':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
  
  // Yeni kullanıcı ekleme dialogu
  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'Kullanıcı';
    String selectedStatus = 'Aktif';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Kullanıcı Ekle'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Kullanıcı', child: Text('Kullanıcı')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Pasif', child: Text('Pasif')),
                    DropdownMenuItem(value: 'Beklemede', child: Text('Beklemede')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ekle'),
              onPressed: () async {
                try {
                  final newUser = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': selectedRole,
                    'status': selectedStatus,
                  };
                  
                  Navigator.of(context).pop();
                  await _addUser(newUser);
                  
                  // Kullanıcıları yeniden yükle
                  _fetchUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kullanıcı eklenirken hata: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  // Kullanıcı düzenleme dialogu
  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'];
    String selectedStatus = user['status'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kullanıcı Düzenle'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Kullanıcı', child: Text('Kullanıcı')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Durum'),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Pasif', child: Text('Pasif')),
                    DropdownMenuItem(value: 'Beklemede', child: Text('Beklemede')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () async {
                try {
                  final updatedUser = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': selectedRole,
                    'status': selectedStatus,
                  };
                  
                  Navigator.of(context).pop();
                  await _updateUser(user['id'], updatedUser);
                  
                  // Kullanıcıları yeniden yükle
                  _fetchUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kullanıcı güncellenirken hata: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kullanıcı Sil'),
          content: Text(
            '${user['name']} isimli kullanıcıyı silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Sil',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  await _deleteUser(user['id']);
                  
                  // Kullanıcıları yeniden yükle
                  _fetchUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kullanıcı silinirken hata: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
} 