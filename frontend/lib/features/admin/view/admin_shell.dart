import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_widgets.dart';
import 'admin_students_screen.dart';
import 'admin_academic_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'admin_section_screen.dart';

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
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Quản trị'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Cài đặt'),
          ],
        ),
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
        title: 'Quản lý tài khoản Admin',
        subtitle: 'Danh sách tài khoản admin',
        icon: Icons.manage_accounts_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
      ),
      _AdminMenuItem(
        title: 'Quản lý sinh viên',
        subtitle: 'Danh sách sinh viên NLU',
        icon: Icons.people_alt_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen())),
      ),
      _AdminMenuItem(
        title: 'Quản lý học thuật',
        subtitle: 'Môn học - Nhập điểm',
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAcademicScreen())),
      ),
      _AdminMenuItem(
        title: 'Quản lý lịch học',
        subtitle: 'Quản lý học phần - Sắp xếp ca học',
        icon: Icons.class_outlined,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSectionScreen())),
      ),
      const _AdminMenuItem(title: 'Quản lý chatbot', subtitle: 'Lịch sử chat', icon: Icons.smart_toy_outlined),
      const _AdminMenuItem(title: 'Quản lý thông báo', subtitle: 'Gửi thông báo', icon: Icons.notifications_outlined),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(context, 'Trang quản trị'),
      body: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap ?? () => _showComingSoon(context),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(item.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    AdminNotification.showInfo(context, 'Chức năng sẽ được cập nhật ở bước tiếp theo',
        title: 'Sắp ra mắt');
  }
}

class _AdminMenuItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  const _AdminMenuItem({required this.title, this.subtitle, required this.icon, this.onTap});
}
