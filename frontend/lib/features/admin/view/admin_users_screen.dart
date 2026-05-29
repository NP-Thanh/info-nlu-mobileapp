import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = AdminRepository();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAdminUsers(keyword: _searchController.text);
      if (!mounted) return;
      setState(() => _users = list);
    } on DioException catch (e) {
      _snack(e.response?.data?['message'] ?? 'Không tải được danh sách');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() => setState(() {
        _selectionMode = true;
        _selectedIds
          ..clear()
          ..addAll(_users.map((u) => (u['id'] as num).toInt()));
      });

  void _exitSelection() => setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Xóa ${_selectedIds.length} tài khoản admin đã chọn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: AdminTheme.primaryButtonStyle().copyWith(backgroundColor: WidgetStateProperty.all(Colors.red)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteAdminUsers(_selectedIds.toList());
      _exitSelection();
      _fetch();
      _snack('Đã xóa ${_selectedIds.length} tài khoản');
    } on DioException catch (e) {
      _snack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  Future<void> _openAddDialog() async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final confirmEmailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm tài khoản Admin'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: AdminTheme.inputDecoration('Username'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Không được để trống';
                      if (v.trim().length < 3) return 'Tối thiểu 3 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AdminTheme.inputDecoration('Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Không được để trống';
                      final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AdminTheme.inputDecoration('Xác nhận Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Không được để trống';
                      if (v.trim() != emailCtrl.text.trim()) return 'Email không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mật khẩu sẽ được tạo tự động và gửi đến email trên.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: AdminTheme.primaryButtonStyle(),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _repo.createAdminUser(
                          username: usernameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetch();
                        _snack('Tạo tài khoản thành công, mật khẩu đã gửi qua email');
                      } on DioException catch (e) {
                        setDialogState(() => saving = false);
                        _snack(e.response?.data?['message'] ?? 'Tạo thất bại');
                      } catch (_) {
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _selectionMode
            ? Text('Đã chọn ${_selectedIds.length}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))
            : const Text('Quản lý tài khoản Admin', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: _selectionMode
            ? [
                TextButton(onPressed: _selectAll, child: const Text('Tất cả')),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _deleteSelected),
                IconButton(icon: const Icon(Icons.close), onPressed: _exitSelection),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
                  tooltip: 'Thêm admin',
                  onPressed: _openAddDialog,
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: AdminTheme.inputDecoration(
                'Tìm theo username',
                prefixIcon: const Icon(Icons.search, size: 20),
              ).copyWith(
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetch();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _fetch(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _users.isEmpty
                    ? const Center(child: Text('Không có tài khoản nào'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final u = _users[index];
                          final id = (u['id'] as num).toInt();
                          final selected = _selectedIds.contains(id);

                          return GestureDetector(
                            onLongPress: () => _selectionMode ? null : _enterSelection(id),
                            onTap: () => _selectionMode ? _toggleSelect(id) : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_selectionMode)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(
                                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: selected ? AppColors.primary : AppColors.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    child: Text(
                                      u['username'].toString()[0].toUpperCase(),
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u['username']?.toString() ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          u['email']?.toString() ?? '—',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ngày tạo: ${_formatDate(u['createdAt']?.toString())}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                ],
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
