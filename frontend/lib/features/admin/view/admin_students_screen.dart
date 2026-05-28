import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _repo = AdminRepository();
  final _keywordController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getStudents(keyword: _keywordController.text);
      if (!mounted) return;
      setState(() => _students = list);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách sinh viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      await _repo.deleteStudent(id);
      _showSnack('Đã xóa sinh viên');
      _fetchStudents();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  Future<void> _openStudentForm({Map<String, dynamic>? student}) async {
    final studentCodeController = TextEditingController(text: student?['studentCode']?.toString() ?? '');
    final fullNameController = TextEditingController(text: student?['fullName']?.toString() ?? '');
    final emailController = TextEditingController(text: student?['email']?.toString() ?? '');
    final startYearController = TextEditingController(text: student?['startYear']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? 'Thêm sinh viên' : 'Cập nhật sinh viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: studentCodeController, decoration: const InputDecoration(labelText: 'MSSV')),
              TextField(controller: fullNameController, decoration: const InputDecoration(labelText: 'Họ tên')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                controller: startYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Năm vào học'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );

    if (result != true) return;

    final payload = {
      'studentCode': studentCodeController.text.trim(),
      'fullName': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'startYear': int.tryParse(startYearController.text.trim()),
      'status': 'Đang học',
      'gender': 'Nam',
      'phone': '0123456789',
      'dateOfBirth': '2000-01-01',
      'endYear': (int.tryParse(startYearController.text.trim()) ?? 2022) + 4,
    };

    try {
      if (student == null) {
        await _repo.createStudent(payload);
      } else {
        await _repo.updateStudent((student['id'] as num).toInt(), payload);
      }
      _showSnack('Lưu sinh viên thành công');
      _fetchStudents();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sinh viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openStudentForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo MSSV hoặc tên',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _fetchStudents, child: const Text('Tìm')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _students.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      return ListTile(
                        title: Text('${s['fullName'] ?? ''} (${s['studentCode'] ?? ''})'),
                        subtitle: Text(s['email']?.toString() ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () => _openStudentForm(student: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteStudent((s['id'] as num).toInt()),
                            ),
                          ],
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
