import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AccountScreen extends StatefulWidget {
  final bool inPanel;
  final Map<String, dynamic>? userData;
  final Function refreshParent;

  const AccountScreen({
    Key? key,
    this.inPanel = false,
    required this.userData,
    required this.refreshParent,
  }) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _showPassword = false;
  bool _passwordChangeMode = false;

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _surnameController = TextEditingController(text: widget.userData?['surname'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getUpdateProfileUrl() {
    // Şimdilik mevcut kullanıcı ID'si ile test amaçlı bir URL kullanıyoruz
    // Gerçek uygulamada burada firebase uid kullanılmalı
    String userId = "current-user"; // Firebase user ID buraya gelmeli
    
    if (kIsWeb) {
      // Web için yerel endpoint
      return 'http://localhost:8000/api/auth/update';
    } else {
      // Emulator için endpoint
      return 'http://10.0.2.2:8000/api/auth/update';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Boşlukları ve özel karakterleri kaldır
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 10 && cleanPhone.length <= 11;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      print("Form doğrulama başarısız");
      return;
    }

    // Ek doğrulamalar
    if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _errorMessage = "Geçerli bir e-posta adresi giriniz";
      });
      print("Geçersiz e-posta formatı");
      return;
    }

    if (!_isValidPhone(_phoneController.text)) {
      setState(() {
        _errorMessage = "Geçerli bir telefon numarası giriniz";
      });
      print("Geçersiz telefon formatı");
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("Token bulunamadı");
      setState(() {
        isLoading = false;
        _errorMessage = "Oturum bilgisi bulunamadı";
      });
      return;
    }

    try {
      print("Profil güncelleme işlemi başlatılıyor...");
      
      // Başındaki ve sonundaki boşlukları temizle
      final name = _nameController.text.trim();
      final surname = _surnameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      
      print("Kullanıcı bilgileri: İsim: $name, Soyisim: $surname, Telefon: $phone, E-posta: $email");

      final Map<String, dynamic> requestData = {
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
      };

      if (_passwordChangeMode) {
        print("Şifre değiştirme modu aktif");
        if (_currentPasswordController.text.isNotEmpty &&
            _newPasswordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty) {
          if (_newPasswordController.text != _confirmPasswordController.text) {
            print("Yeni şifreler eşleşmiyor");
            setState(() {
              isLoading = false;
              _errorMessage = "Yeni şifreler eşleşmiyor";
            });
            return;
          }
          
          if (_newPasswordController.text.length < 6) {
            print("Şifre çok kısa");
            setState(() {
              isLoading = false;
              _errorMessage = "Yeni şifre en az 6 karakter olmalıdır";
            });
            return;
          }
          
          requestData['current_password'] = _currentPasswordController.text;
          requestData['new_password'] = _newPasswordController.text;
          requestData['new_password_confirmation'] = _confirmPasswordController.text;
          print("Şifre değiştirme bilgileri eklendi");
        } else {
          print("Şifre alanları tam doldurulmadı");
        }
      }

      final String updateUrl = _getUpdateProfileUrl();
      print("İstek URL: $updateUrl");
      print("İstek verisi: ${json.encode(requestData)}");
      print("Authorization: Bearer $token");
      
      // Gerçek HTTP isteği
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print("Sunucu yanıtı: Durum Kodu: ${response.statusCode}");
      print("Yanıt içeriği: ${response.body}");

      if (response.statusCode == 200) {
        print("Profil başarıyla güncellendi");
        
        // Yanıt içeriğini ayrıştır
        final responseData = json.decode(response.body);
        final userData = responseData['user_data'];
        
        setState(() {
          isLoading = false;
          _successMessage = "Profil bilgileriniz başarıyla güncellendi";
          
          if (_passwordChangeMode) {
            _passwordChangeMode = false;
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          }
          
          // Kullanıcı verilerini yerel olarak güncelle
          if (widget.userData != null && userData != null) {
            widget.userData!["name"] = userData["name"];
            widget.userData!["surname"] = userData["surname"];
            widget.userData!["phone"] = userData["phone"];
            widget.userData!["email"] = userData["email"];
            
            // SharedPreferences'e güncellenmiş verileri kaydet
            prefs.setString('userData', json.encode(widget.userData));
            
            print("Kullanıcı verileri yerel olarak güncellendi");
          }
        });
        
        // Üst widget'ı yenile
        widget.refreshParent();
      } else {
        // API yanıt mesajını işleme
        String errorMsg = "Profil güncellenirken bir hata oluştu";
        
        try {
          final errorData = json.decode(response.body);
          print("Profil güncelleme hatası: ${response.statusCode}, Mesaj: ${errorData}");
          
          if (errorData.containsKey('message')) {
            errorMsg = errorData['message'];
          } else if (errorData.containsKey('error')) {
            errorMsg = errorData['error'];
          } else if (errorData.containsKey('detail')) {
            errorMsg = errorData['detail'];
          }
          
          // Validasyon hataları için
          if (errorData.containsKey('errors')) {
            final errors = errorData['errors'];
            if (errors is Map) {
              final firstErrorField = errors.keys.first;
              final firstError = errors[firstErrorField][0];
              errorMsg = firstError ?? errorMsg;
            }
          }
        } catch (e) {
          print("Hata yanıtı ayrıştırma hatası: $e");
          errorMsg = "Sunucu yanıtı işlenirken hata oluştu: ${response.body}";
        }
        
        setState(() {
          isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      print("İstek hatası: $e");
      setState(() {
        isLoading = false;
        _errorMessage = "Bağlantı hatası: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standart arkaplan rengi
    const backgroundColor = Color(0xFF232323);
    const cardColor = Color(0xFF2A2A2A);
    const accentColor = Colors.deepOrange;
    
    // Başlık widget'ı
    final headerWidget = Column(
      children: [
        // Profil resmi
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(top: 15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
            image: widget.userData != null && widget.userData!['profile_image'] != null
                ? DecorationImage(
                    image: NetworkImage(widget.userData!['profile_image']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.userData == null || widget.userData!['profile_image'] == null
              ? const Icon(Icons.person, color: Colors.white, size: 50)
              : null,
        ),
        const SizedBox(height: 15),
        
        // Kullanıcı adı
        Text(
          "${widget.userData?['name'] ?? ''} ${widget.userData?['surname'] ?? ''}",
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        
        // Kullanıcı telefon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.grey[400], size: 16),
            const SizedBox(width: 6),
            Text(
              widget.userData?['phone'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Kullanıcı e-posta
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, color: Colors.grey[400], size: 16),
            const SizedBox(width: 6),
            Text(
              widget.userData?['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );

    // Kişisel bilgiler bölümü
    final personalInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kişisel bilgiler başlığı
        Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 18, left: 10),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: accentColor, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Kişisel Bilgiler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Form alanları
        _buildSimpleFormField(
          label: 'İsim',
          icon: Icons.person,
          controller: _nameController,
        ),
        
        _buildSimpleFormField(
          label: 'Soyisim',
          icon: Icons.person,
          controller: _surnameController,
        ),
        
        _buildSimpleFormField(
          label: 'Telefon',
          icon: Icons.phone,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        
        _buildSimpleFormField(
          label: 'E-posta',
          icon: Icons.email,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );

    // Şifre değiştirme bölümü
    final passwordSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Şifre değiştirme başlığı ve switch
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.15),
                Colors.grey.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: accentColor, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Şifre Değiştir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _passwordChangeMode,
                  onChanged: (value) {
                    setState(() {
                      _passwordChangeMode = value;
                      if (!value) {
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  activeColor: Colors.white,
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        
        // Şifre form alanları
        if (_passwordChangeMode) ...[
          _buildSimpleFormField(
            label: 'Mevcut Şifre',
            icon: Icons.lock,
            controller: _currentPasswordController,
            obscureText: !_showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),
          
          _buildSimpleFormField(
            label: 'Yeni Şifre',
            icon: Icons.lock,
            controller: _newPasswordController,
            obscureText: true,
          ),
          
          _buildSimpleFormField(
            label: 'Şifre Tekrar',
            icon: Icons.lock,
            controller: _confirmPasswordController,
            obscureText: true,
          ),
          
          // Şifre güvenlik notu
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 5, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 14),
                const SizedBox(width: 8),
                Text(
                  'Şifreniz en az 6 karakter olmalıdır',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    // Güncelleme butonu
    final updateButton = Container(
      width: double.infinity,
      height: 54,
      margin: const EdgeInsets.only(top: 28, bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.8),
            accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bilgileri Güncelle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );

    // Mesaj widget'ı
    final messagesWidget = Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.12),
                  Colors.red.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[300], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        
        if (_successMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.12),
                  Colors.green.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[300], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[300], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    // Yan panel yapısı
    if (widget.inPanel) {
      // Panel genişliği - ekran boyutuna uyarlanmış
      final screenWidth = MediaQuery.of(context).size.width;
      final panelWidth = screenWidth < 600 ? screenWidth * 0.5 : 400.0;
      
      return Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Hesabım', 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )
              ),
              backgroundColor: backgroundColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              toolbarHeight: 50,
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                children: [
                  headerWidget,
                  const SizedBox(height: 8),
                  messagesWidget,
                  personalInfoSection,
                  passwordSection,
                  updateButton,
                  const SizedBox(height: 20), // Ekstra alt boşluk
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tam ekran yapısı
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Hesabım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            children: [
              headerWidget,
              const SizedBox(height: 16),
              messagesWidget,
              personalInfoSection,
              passwordSection,
              updateButton,
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Basit form alanı
  Widget _buildSimpleFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    // Text alanındaki mevcut değer
    final hasValue = controller.text.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: hasValue ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(
              icon, 
              color: hasValue ? Colors.grey[300] : Colors.grey[400], 
              size: 20
            ),
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          errorStyle: TextStyle(
            color: Colors.red[300],
            fontSize: 12,
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bu alan boş bırakılamaz';
          }
          
          if (keyboardType == TextInputType.emailAddress) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi giriniz';
            }
          }
          
          if (keyboardType == TextInputType.phone) {
            if (!RegExp(r'^\d{10,11}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
              return 'Geçerli bir telefon numarası giriniz';
            }
          }
          
          return null;
        },
      ),
    );
  }
} 