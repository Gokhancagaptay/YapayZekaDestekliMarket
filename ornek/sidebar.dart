import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;
  final bool isExpanded;
  
  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
    this.isExpanded = true,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('isAdmin', false);
    
    // Dummy API logout
    try {
      // API çağrısı yapılabilir - şimdilik boş
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Logout error: $e');
    }
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded ? 250 : 80,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(0, Icons.dashboard, 'Dashboard'),
                _buildMenuItem(1, Icons.people, 'Kullanıcılar'),
                _buildMenuItem(2, Icons.inventory, 'Ürünler'),
                _buildMenuItem(3, Icons.shopping_cart, 'Siparişler'),
                _buildMenuItem(4, Icons.inventory_2, 'Stok'),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: isExpanded ? const Text('Çıkış Yap') : null,
            minLeadingWidth: 0,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isExpanded
          ? const Row(
              children: [
                Icon(Icons.shopping_cart, size: 24),
                SizedBox(width: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : const Icon(Icons.shopping_cart, size: 24),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemTap(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange.withOpacity(0.2) : null,
            border: Border(
              left: BorderSide(
                width: 4,
                color: isSelected ? Colors.deepOrange : Colors.transparent,
              ),
            ),
          ),
          child: ListTile(
            selected: isSelected,
            leading: Icon(
              icon,
              color: isSelected ? Colors.deepOrange : null,
            ),
            title: isExpanded
                ? Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  )
                : null,
            minLeadingWidth: 0,
          ),
        ),
      ),
    );
  }
} 