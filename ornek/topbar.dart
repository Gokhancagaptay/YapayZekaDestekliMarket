import 'package:flutter/material.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  const AdminTopBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Bildirim işlevi
          },
        ),
        const SizedBox(width: 8),
        _buildAdminAvatar(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAdminAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          // Profil menüsü
          _showProfileMenu(context);
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Admin'),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 8),
              Text('Profil'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 8),
              Text('Ayarlar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Çıkış Yap'),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'logout') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 