import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase/firebase_web_stub.dart';
import '../constants/constants.dart';
import 'widgets/admin_topbar.dart';
import 'widgets/admin_table.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({Key? key}) : super(key: key);

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('users');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map;
        List<Map<String, dynamic>> userList = [];
        
        users.forEach((key, value) {
          if (value is Map) {
            userList.add({
              'id': key,
              'name': value['name'] ?? 'İsimsiz',
              'email': value['email'] ?? '',
              'phone': value['phone'] ?? '',
              'role': value['role'] ?? 'user',
              'addresses': value['addresses'] ?? [],
            });
          }
        });

        setState(() {
          _users = userList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Kullanıcılar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      return user['name'].toString().toLowerCase().contains(query) ||
          user['email'].toString().toLowerCase().contains(query) ||
          user['phone'].toString().toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseDatabase.instance
          .ref('users/$userId')
          .update({'role': newRole});
          
      setState(() {
        final index = _users.indexWhere((user) => user['id'] == userId);
        if (index != -1) {
          _users[index]['role'] = newRole;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı rolü güncellendi')),
      );
    } catch (e) {
      print('Rol güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol güncellenemedi, lütfen tekrar deneyin')),
      );
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF333333),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    radius: 24,
                    child: Text(
                      user['name'].toString().isNotEmpty
                          ? user['name'].toString()[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user['role']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user['role'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: _getRoleColor(user['role']),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.edit, size: 16),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'admin', child: Text('Admin')),
                                const PopupMenuItem(value: 'user', child: Text('Kullanıcı')),
                              ],
                              onSelected: (role) {
                                Navigator.pop(context);
                                _updateUserRole(user['id'], role);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(Icons.email, 'Email', user['email']),
              _detailRow(Icons.phone, 'Telefon', user['phone']),
              const SizedBox(height: 16),
              Text(
                'Adresler',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (user['addresses'] is List && (user['addresses'] as List).isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (user['addresses'] as List).length,
                  itemBuilder: (context, index) {
                    final address = (user['addresses'] as List)[index];
                    if (address is Map) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on, color: Colors.deepOrange),
                        title: Text(
                          address['title'] ?? 'Adres ${index + 1}',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                        subtitle: Text(
                          address['address'] ?? '',
                          style: GoogleFonts.montserrat(color: Colors.grey),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Kayıtlı adres bulunmuyor',
                    style: GoogleFonts.montserrat(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kapat',
                      style: GoogleFonts.montserrat(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepOrange;
      case 'moderator':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      body: Column(
        children: [
          AdminTopbar(
            title: 'Kullanıcı Yönetimi',
            actions: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: GoogleFonts.montserrat(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF424242),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Yenile',
                color: Colors.white,
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AdminTable<Map<String, dynamic>>(
                columns: const ['Kullanıcı', 'Email', 'Telefon', 'Rol', 'İşlemler'],
                data: _filteredUsers,
                isLoading: _isLoading,
                onRowTap: _showUserDetails,
                cellBuilder: (user, index) => [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          radius: 16,
                          child: Text(
                            user['name'].toString().isNotEmpty
                                ? user['name'].toString()[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user['name'],
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(
                    user['email'],
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
                  DataCell(Text(
                    user['phone'],
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user['role']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['role'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: _getRoleColor(user['role']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ActionCell(
                      actions: [
                        ActionItem(
                          icon: Icons.visibility,
                          onPressed: () => _showUserDetails(user),
                          tooltip: 'Detay',
                          color: Colors.blue,
                        ),
                        ActionItem(
                          icon: Icons.edit,
                          onPressed: () {
                            // Düzenleme fonksiyonu
                          },
                          tooltip: 'Düzenle',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 