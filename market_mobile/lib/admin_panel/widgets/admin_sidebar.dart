import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _SidebarItem(icon: Icons.dashboard, title: 'Dashboard'),
      _SidebarItem(icon: Icons.people, title: 'Kullanıcılar'),
      _SidebarItem(icon: Icons.inventory, title: 'Ürünler'),
      _SidebarItem(icon: Icons.shopping_cart, title: 'Siparişler'),
      _SidebarItem(icon: Icons.storage, title: 'Stok'),
      _SidebarItem(icon: Icons.analytics, title: 'Raporlar'),
      _SidebarItem(icon: Icons.settings, title: 'Ayarlar'),
    ];

    return Container(
      width: 250,
      color: const Color(0xFF212121),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.store, size: 40, color: Colors.deepOrange),
                const SizedBox(height: 8),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepOrange.withOpacity(0.2) : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? Colors.deepOrange : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            items[index].icon,
                            size: 22,
                            color: isSelected ? Colors.deepOrange : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            items[index].title,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SidebarItem {
  final IconData icon;
  final String title;

  _SidebarItem({
    required this.icon,
    required this.title,
  });
} 