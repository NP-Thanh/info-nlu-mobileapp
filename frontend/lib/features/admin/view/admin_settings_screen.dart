import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/view/change_password_screen.dart';
import '../../auth/view/login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String _username = '';
  String _fullName = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('studentCode') ?? '';
      _fullName = prefs.getString('fullName') ?? '';
    });
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    try {
      await AuthRepository().logout();
    }
    finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(context, 'Cài đặt tài khoản'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminTheme.infoCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(_fullName.isEmpty ? 'ADMIN' : _fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Tài khoản: $_username'),
                ),
              ),
              const SizedBox(height: 12),
              AdminTheme.infoCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      title: const Text('Đổi mật khẩu'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
