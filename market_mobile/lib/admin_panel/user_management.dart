import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // Servis içinde kullanılıyor, burada gereksiz
// import '../firebase/firebase_web_stub.dart'; // Yorumlandı
import 'services/admin_user_service.dart'; // Yeni kullanıcı servisi import edildi

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final AdminUserService _userService = AdminUserService(); // Servis örneği
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _errorMessage = '';
  String _searchTerm = ''; // Arama için

  // Filtreleme için
  String? _selectedRoleFilter;
  String? _selectedStatusFilter;

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
      // Servisten gelen kullanıcılar artık 'uid' anahtarını içeriyor.
      _users = await _userService.fetchUsers();
      print('UserManagement: ${_users.length} kullanıcı servisten yüklendi.');
    } catch (e) {
      print('UserManagement: Kullanıcı yükleme hatası: $e');
      _errorMessage = "Kullanıcılar yüklenirken bir hata oluştu: ${e.toString()}";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
      setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _userService.updateUserRole(userId, newRole);
      print('UserManagement: Kullanıcı ($userId) rolü başarıyla güncellendi.');
      await _fetchUsers(); // Listeyi yenile
      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı rolü başarıyla güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('UserManagement: Kullanıcı rolü güncelleme hatası: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı rolü güncellenemedi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setUserDisabledStatus(String userId, bool isDisabled) async {
    try {
      await _userService.setUserDisabledStatus(userId, isDisabled);
      print('UserManagement: Kullanıcı ($userId) durumu başarıyla güncellendi.');
      await _fetchUsers(); // Listeyi yenile
      if (mounted) {
        // Edit dialog içinde bu işlem yapılıyorsa dialog açık kalabilir veya kapanabilir.
        // Şimdilik dialog'u kapatmıyoruz, kullanıcı başka değişiklikler de yapabilir.
        // Eğer ayrı bir butonla yapılıyorsa, dialog kapatılabilir.
        // Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı durumu başarıyla güncellendi (${isDisabled ? "Devre Dışı" : "Aktif"})'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('UserManagement: Kullanıcı durumu güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı durumu güncellenemedi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async { // user ID artık String (uid)
    final userToDelete = _users.firstWhere((u) => u['uid'] == userId, orElse: () => {});
    final userEmail = userToDelete['email'] ?? 'Bilinmeyen Kullanıcı';

    if (!mounted) return;
    // Onay dialogu göster
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kullanıcıyı Sil'),
          content: Text(
            '$userEmail adlı kullanıcıyı kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() { _isLoading = true; });
      try {
        await _userService.deleteUser(userId);
        print('UserManagement: Kullanıcı ($userId) başarıyla silindi.');
        await _fetchUsers(); // Listeyi yenile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$userEmail kullanıcısı başarıyla silindi'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('UserManagement: Kullanıcı silme hatası: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kullanıcı silinemedi: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final TextEditingController nameController = TextEditingController(text: user['displayName'] ?? user['name']); // displayName veya name kullan
    final TextEditingController emailController = TextEditingController(text: user['email']);
    String currentRole = user['role'] ?? 'user'; // API'den gelen role
    bool currentDisabledStatus = user['disabled'] ?? false; // API'den gelen disabled durumu

    // Form anahtarı
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Dialog içindeki state değişiklikleri için
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Kullanıcıyı Düzenle'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        enabled: false, // Ad soyad backend'den (Firebase Auth) geliyor, düzenlenemez
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'E-posta'),
                        enabled: false, // E-posta backend'den (Firebase Auth) geliyor, düzenlenemez
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Rol'),
                        value: currentRole,
                        items: ['user', 'admin'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value == 'admin' ? 'Admin' : 'Kullanıcı'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() { // Dialog state'ini güncelle
                              currentRole = newValue;
                            });
                          }
                        },
                        validator: (value) => value == null ? 'Rol seçimi zorunludur' : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Hesap Devre Dışı'),
                        value: currentDisabledStatus,
                        onChanged: (bool value) {
                          setDialogState(() { // Dialog state'ini güncelle
                            currentDisabledStatus = value;
                          });
                        },
                        subtitle: Text(currentDisabledStatus ? 'Kullanıcı giriş yapamaz' : 'Kullanıcı aktif'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Kaydet'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Rol değişikliği varsa güncelle
                      if (user['role'] != currentRole) {
                        await _updateUserRole(user['uid'], currentRole);
                      }
                      // Durum değişikliği varsa güncelle
                      if (user['disabled'] != currentDisabledStatus) {
                        await _setUserDisabledStatus(user['uid'], currentDisabledStatus);
                      }
                      // Eğer hiçbir değişiklik yapılmadıysa sadece dialogu kapat
                      if (user['role'] == currentRole && user['disabled'] == currentDisabledStatus) {
                         if (mounted) Navigator.of(context).pop();
                      }
                      // Not: _updateUserRole ve _setUserDisabledStatus kendi içlerinde listeyi yenileyip dialogu kapatabilir veya snackbar gösterebilir.
                      // Ancak burada sadece değişiklik varsa çağırıyoruz.
                      // Listeyi yenileme ve dialog kapama işlemleri ilgili fonksiyonlar içinde yapılıyor.
                      // Eğer ikisi de çağrılmazsa ve değişiklik yoksa dialog burada kapatılır.
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> usersToFilter = List.from(_users);

    if (_searchTerm.isNotEmpty) {
      usersToFilter = usersToFilter.where((user) {
        final name = (user['displayName'] as String? ?? '').toLowerCase();
        final email = (user['email'] as String? ?? '').toLowerCase();
        final term = _searchTerm.toLowerCase();
        return name.contains(term) || email.contains(term);
      }).toList();
    }

    if (_selectedRoleFilter != null && _selectedRoleFilter != 'all') {
      usersToFilter = usersToFilter.where((user) => user['role'] == _selectedRoleFilter).toList();
    }

    if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
      usersToFilter = usersToFilter.where((user) {
        if (_selectedStatusFilter == 'active') return !(user['disabled'] ?? false);
        if (_selectedStatusFilter == 'disabled') return (user['disabled'] ?? false);
        return true;
      }).toList();
    }
    return usersToFilter;
  }

  @override
  Widget build(BuildContext context) {
    // Filtrelenmiş kullanıcı listesi
    List<Map<String, dynamic>> filteredUsers = _users.where((user) {
      final name = user['displayName']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final role = user['role']?.toString().toLowerCase() ?? '';
      final isDisabled = user['disabled'] as bool? ?? false;
      final status = isDisabled ? "disabled" : "active";

      final roleMatch = _selectedRoleFilter == null || _selectedRoleFilter == 'all' || role == _selectedRoleFilter;
      final statusMatch = _selectedStatusFilter == null || _selectedStatusFilter == 'all' || status == _selectedStatusFilter;
      final searchMatch = _searchTerm.isEmpty || name.contains(_searchTerm.toLowerCase()) || email.contains(_searchTerm.toLowerCase());

      return roleMatch && statusMatch && searchMatch;
    }).toList();

    return Scaffold(
      // appBar: AppBar(title: const Text('Kullanıcı Yönetimi')), // İsteğe bağlı AppBar
      body: SingleChildScrollView( // Added SingleChildScrollView
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kullanıcı Yönetimi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                  onPressed: _fetchUsers,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilters(context),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
            else if (filteredUsers.isEmpty)
              const Center(child: Text('Filtreye uygun kullanıcı bulunamadı.'))
            else
              _buildUserTable(context, filteredUsers), // buildUserTable metodu çağrılır
          ],
        ),
      ), // Closed SingleChildScrollView
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0), // Dikey padding artırıldı
        child: Wrap(
          spacing: 16.0, // Yatay boşluk
          runSpacing: 12.0, // Dikey boşluk (alt satıra geçtiğinde)
          alignment: WrapAlignment.start,
                  children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 400), // Arama çubuğu için esnek genişlik
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ad veya E-posta ile ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: InputBorder.none, 
                  isDense: true,
                  hintStyle: TextStyle(color: Colors.grey[600])
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150), // Rol filtresi için minimum genişlik
              child: DropdownButtonFormField<String>(
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                value: _selectedRoleFilter,
                hint: const Text('Tümü'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tüm Roller')),
                  const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  const DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRoleFilter = value;
                  });
                },
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150), // Durum filtresi için minimum genişlik
              child: DropdownButtonFormField<String>(
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                value: _selectedStatusFilter,
                hint: const Text('Tümü'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tüm Durumlar')),
                  const DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  const DropdownMenuItem(value: 'disabled', child: Text('Devre Dışı')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatusFilter = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable(BuildContext context, List<Map<String, dynamic>> users) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView( // Yatay kaydırma için
        scrollDirection: Axis.horizontal,
          child: DataTable(
          columnSpacing: 25, // Sütun aralığı
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey.shade50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            columns: const [
              DataColumn(label: Text('Ad Soyad')),
              DataColumn(label: Text('E-posta')),
              DataColumn(label: Text('Rol')),
              DataColumn(label: Text('Durum')),
            DataColumn(label: Text('Oluşturulma T.')),
            DataColumn(label: Text('Son Giriş T.')),
              DataColumn(label: Text('İşlemler')),
            ],
            rows: users.map((user) {
            // displayName için API'den gelen 'name' ve 'surname' kullanılabilir veya direkt 'displayName'
            String displayName = user['displayName'] ?? '';
            if (displayName.isEmpty && (user['name'] != null || user['surname'] != null)) {
                 displayName = ('${user['name'] ?? ''} ${user['surname'] ?? ''}').trim();
            }
            if (displayName.isEmpty) displayName = 'Belirtilmemiş';

            String creationTimestamp = user['creationTimestamp'] != null
                ? _formatDate(user['creationTimestamp'])
                : '-';
            String lastSignInTimestamp = user['lastSignInTimestamp'] != null
                ? _formatDate(user['lastSignInTimestamp'])
                : '-';

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                }
                // Satırları ayırt etmek için hafif bir renk eklenebilir
                // if (users.indexOf(user) % 2 == 0) return Colors.grey.withOpacity(0.1);
                return null; 
              }),
              cells: [
                DataCell(
                  Row(children: [
                    if (user['photoURL'] != null && (user['photoURL'] as String).isNotEmpty)
                      CircleAvatar(backgroundImage: NetworkImage(user['photoURL']), radius: 15)
                    else
                      CircleAvatar(child: Icon(Icons.person, size: 18), radius: 15),
                    const SizedBox(width: 8),
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ]),
                ),
                DataCell(SelectableText(user['email'] ?? 'N/A')), // E-posta seçilebilir
                DataCell(Text(user['role'] == 'admin' ? 'Admin' : 'Kullanıcı', style: TextStyle(color: user['role'] == 'admin' ? Colors.teal : Colors.blueGrey, fontWeight: FontWeight.w500))),
                DataCell(_buildStatusChip(user['disabled'] ?? false)),
                DataCell(Text(creationTimestamp)),
                DataCell(Text(lastSignInTimestamp)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: "Düzenle (Rol/Durum)",
                      child: IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blueAccent, size: 22),
                      onPressed: () {
                          _showEditUserDialog(context, user); // user['uid'] gerekli
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: "Kullanıcıyı Sil",
                      child: IconButton(
                        icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 22),
                      onPressed: () {
                          _deleteUser(user['uid']); // user['uid'] gerekli
                      },
                      ),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
      ),
    );
  }
  
  String _formatDate(String? isoDateString) {
    if (isoDateString == null || isoDateString.isEmpty) return '-';
    try {
      DateTime dateTime = DateTime.parse(isoDateString);
      // Sadece tarih veya tarih ve saat olarak formatlayabilirsiniz.
      // return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                } catch (e) {
      print("Tarih formatlama hatası: $isoDateString, Hata: $e");
      return isoDateString; // Hata durumunda orijinal stringi dön
    }
  }

  Widget _buildStatusChip(bool isDisabled) {
    return Chip(
      avatar: Icon(
        isDisabled ? Icons.do_not_disturb_on : Icons.check_circle,
        color: isDisabled ? Colors.red.shade700 : Colors.green.shade700,
        size: 16,
      ),
      label: Text(
        isDisabled ? 'Devre Dışı' : 'Aktif',
        style: TextStyle(
          color: isDisabled ? Colors.red.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isDisabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: const EdgeInsets.only(left: 4), // İkon ile yazı arasını ayarla
    );
  }
} 