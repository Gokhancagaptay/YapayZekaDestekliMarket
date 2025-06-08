import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTopbar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const AdminTopbar({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          ...?actions,
          const SizedBox(width: 16),
          _ProfileButton(),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF333333),
      icon: CircleAvatar(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'Profil',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'Ayarlar',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'Çıkış',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        // Handle menu item selection
        if (value == 'logout') {
          // Implement logout logic
        }
      },
    );
  }
} 