import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_students_screen.dart';
import 'admin_academic_screen.dart';
import 'admin_settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _AdminMenuScreen(),
    AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}

class _AdminMenuScreen extends StatelessWidget {
  const _AdminMenuScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminMenuItem(
        title: 'Quản lý sinh viên',
        icon: Icons.people_alt_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen())),
      ),
      _AdminMenuItem(
        title: 'Quản lý học thuật',
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAcademicScreen())),
      ),
      const _AdminMenuItem(title: 'Quản lý lịch học', icon: Icons.calendar_month_outlined),
      const _AdminMenuItem(title: 'Quản lý chatbot', icon: Icons.smart_toy_outlined),
      const _AdminMenuItem(title: 'Quản lý thông báo', icon: Icons.notifications_outlined),
      _AdminMenuItem(
        title: 'Cài đặt',
        icon: Icons.settings_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang quản trị'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _MenuCard(item: items[index]),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _AdminMenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap ?? () => _showComingSoon(context),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(item.icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng sẽ được cập nhật ở bước tiếp theo')),
    );
  }
}

class _AdminMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const _AdminMenuItem({required this.title, required this.icon, this.onTap});
}
