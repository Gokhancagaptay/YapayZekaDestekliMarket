import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/admin_topbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/firebase_web_stub.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({Key? key}) : super(key: key);

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  bool _isDarkMode = true;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'Türkçe';
  final _formKey = GlobalKey<FormState>();
  
  // Kullanıcı bilgileri
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  String _userId = '';
  
  // Düzenleme modu
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _autoBackup = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Türkçe';
    });
  }

  Future<void> _loadUserData() async {
    try {
      if (!kIsWeb) { // Web platformunda değilse Firebase'den yükle
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _userId = user.uid;
          _userEmail = user.email ?? '';
          
          // Firebase Realtime Database'den kullanıcı bilgilerini al
          final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
          final snapshot = await userRef.get();
          
          if (snapshot.exists && snapshot.value != null) {
            final userData = snapshot.value as Map<dynamic, dynamic>;
            setState(() {
              _userName = userData['name'] ?? '';
              _userRole = userData['role'] ?? 'user';
              _nameController.text = _userName;
              _emailController.text = _userEmail;
              _isLoading = false;
            });
          } else {
            setState(() {
              _userName = user.displayName ?? 'Admin';
              _userRole = 'admin';
              _nameController.text = _userName;
              _emailController.text = _userEmail;
              _isLoading = false;
            });
          }
        }
      } else {
        // Web platformu için varsayılan değer veya başka bir kaynak 
        setState(() {
          _emailController.text = 'admin@example.com';
        });
      }
    } catch (e) {
      _showSnackBar('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isNotificationsEnabled', _isNotificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayarlar kaydedildi')),
    );
  }
  
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Kullanıcı adını güncelle
        final userRef = FirebaseDatabase.instance.ref('users/$_userId');
        await userRef.update({'name': _nameController.text});
        
        // E-posta değiştiyse Firebase Auth'da da güncelle
        if (_emailController.text != _userEmail) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await user.updateEmail(_emailController.text);
          }
        }
        
        setState(() {
          _userName = _nameController.text;
          _userEmail = _emailController.text;
          _isEditingProfile = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _updateEmail() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Lütfen geçerli bir e-posta adresi girin');
      return;
    }

    if (_oldPasswordController.text.isEmpty) {
      _showSnackBar('Değişiklik yapmak için şifrenizi girmelisiniz');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!kIsWeb) { // Web platformunda değilse Firebase Authentication kullan
        // Yeniden kimlik doğrulama
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _oldPasswordController.text,
          );
          
          await user.reauthenticateWithCredential(credential);
          await user.updateEmail(_emailController.text);
          
          _showSnackBar('E-posta başarıyla güncellendi');
          _oldPasswordController.clear();
        }
      } else {
        // Web platformu için simülasyon
        await Future.delayed(const Duration(seconds: 1));
        _showSnackBar('E-posta güncellenmiş gibi simüle edildi');
        _oldPasswordController.clear();
      }
    } catch (e) {
      _showSnackBar('E-posta güncellenirken hata: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnackBar('Lütfen mevcut ve yeni şifrenizi girin');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Şifre en az 6 karakter uzunluğunda olmalıdır');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!kIsWeb) { // Web platformunda değilse Firebase Authentication kullan
        // Yeniden kimlik doğrulama
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _oldPasswordController.text,
          );
          
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);
          
          _showSnackBar('Şifre başarıyla güncellendi');
          _oldPasswordController.clear();
          _newPasswordController.clear();
        }
      } else {
        // Web platformu için simülasyon
        await Future.delayed(const Duration(seconds: 1));
        _showSnackBar('Şifre güncellenmiş gibi simüle edildi');
        _oldPasswordController.clear();
        _newPasswordController.clear();
      }
    } catch (e) {
      _showSnackBar('Şifre güncellenirken hata: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      
      // Ana sayfaya yönlendir
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: Column(
        children: [
          AdminTopbar(title: 'Ayarlar'),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileSection(),
                                const SizedBox(height: 24),
                                _buildSecuritySection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGeneralSettingsSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepOrange,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditingProfile) ...[
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.montserrat(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad',
                            labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF424242),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ad Soyad boş olamaz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.montserrat(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFF424242),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta boş olamaz';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Text(
                          _userName,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: GoogleFonts.montserrat(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userRole.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEditingProfile) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditingProfile = false;
                        _nameController.text = _userName;
                        _emailController.text = _userEmail;
                      });
                    },
                    child: Text('İptal', style: GoogleFonts.montserrat()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _updateProfile,
                    child: Text('Kaydet', style: GoogleFonts.montserrat()),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: Text('Profili Düzenle', style: GoogleFonts.montserrat()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditingProfile = true;
                      });
                    },
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  label: Text(
                    'Çıkış Yap',
                    style: GoogleFonts.montserrat(color: Colors.grey),
                  ),
                  onPressed: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Güvenlik',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (_isChangingPassword) ...[
              TextFormField(
                controller: _currentPasswordController,
                style: GoogleFonts.montserrat(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mevcut şifre boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                style: GoogleFonts.montserrat(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yeni şifre boş olamaz';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                style: GoogleFonts.montserrat(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF424242),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre tekrarı boş olamaz';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      setState(() {
                        _isChangingPassword = false;
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text('İptal', style: GoogleFonts.montserrat()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _updatePassword,
                    child: Text('Şifreyi Değiştir', style: GoogleFonts.montserrat()),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: Text('Şifre Değiştir', style: GoogleFonts.montserrat()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _isChangingPassword = true;
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security, color: Colors.grey),
              title: Text(
                'İki Faktörlü Doğrulama',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              trailing: Switch(
                value: false, // Varsayılan değer
                onChanged: (value) {
                  // İki faktörlü doğrulama henüz uygulanmadı
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu özellik yakında eklenecek')),
                  );
                },
                activeColor: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF333333),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Ayarlar',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dark_mode, color: Colors.grey),
              title: Text(
                'Karanlık Mod',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
                activeColor: Colors.deepOrange,
              ),
            ),
            const Divider(color: Color(0xFF444444)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications, color: Colors.grey),
              title: Text(
                'Bildirimler',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              trailing: Switch(
                value: _isNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _isNotificationsEnabled = value;
                  });
                },
                activeColor: Colors.deepOrange,
              ),
            ),
            const Divider(color: Color(0xFF444444)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: Colors.grey),
              title: Text(
                'Dil',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF424242),
                style: GoogleFonts.montserrat(color: Colors.white),
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: 'Türkçe', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                  }
                },
              ),
            ),
            const Divider(color: Color(0xFF444444)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveUserSettings,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    'Ayarları Kaydet',
                    style: GoogleFonts.montserrat(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF444444)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Uygulama Sürümü',
                    value: '1.0.0',
                    icon: Icons.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Son Güncelleme',
                    value: '10.05.2023',
                    icon: Icons.update,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Sunucu Durumu',
                    value: 'Çalışıyor',
                    icon: Icons.cloud_done,
                    valueColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
} 