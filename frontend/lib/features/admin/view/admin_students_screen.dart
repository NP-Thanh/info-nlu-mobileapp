import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../utils/student_status.dart';
import '../widgets/admin_widgets.dart';
import 'admin_student_detail_screen.dart';
import 'admin_student_form_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _repo = AdminRepository();
  final _keywordController = TextEditingController();
  final _startYearController = TextEditingController();
  final _classNameController = TextEditingController();
  final _facultyController = TextEditingController();
  String? _selectedStatus;

  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _startYearController.dispose();
    _classNameController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  int? get _startYearFilter => int.tryParse(_startYearController.text.trim());

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getStudents(
        keyword: _keywordController.text,
        className: _classNameController.text,
        faculty: _facultyController.text,
        startYear: _startYearFilter,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() => _students = list);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách sinh viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterSelectionMode(int id) {
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

  void _selectAll() {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(_students.map((s) => (s['id'] as num).toInt()));
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vô hiệu hóa sinh viên'),
        content: Text('Vô hiệu hóa ${_selectedIds.length} sinh viên đã chọn? Họ sẽ không thể đăng nhập.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: AdminTheme.primaryButtonStyle(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      if (_selectedIds.length == 1) {
        await _repo.deleteStudent(_selectedIds.first);
      } else {
        await _repo.deleteStudentsBulk(_selectedIds.toList());
      }
      _showSnack('Đã vô hiệu hóa sinh viên');
      _exitSelectionMode();
      _fetchStudents();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  Future<void> _openDetail(Map<String, dynamic> student) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminStudentDetailScreen(studentId: (student['id'] as num).toInt()),
      ),
    );
    if (changed == true) _fetchStudents();
  }

  Future<void> _openAddForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminStudentFormScreen()),
    );
    if (created == true) _fetchStudents();
  }

  void _resetFilters() {
    _keywordController.clear();
    _startYearController.clear();
    _classNameController.clear();
    _facultyController.clear();
    setState(() => _selectedStatus = null);
    _fetchStudents();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(
        context,
        _selectionMode ? 'Đã chọn ${_selectedIds.length}' : 'Quản lý sinh viên',
        actions: _selectionMode
            ? [
                TextButton(onPressed: _selectAll, child: const Text('Chọn tất cả', style: TextStyle(color: AppColors.primary))),
                IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode),
              ]
            : null,
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddForm,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Thêm SV', style: TextStyle(color: Colors.white)),
            ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  style: AdminTheme.primaryButtonStyle().copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.red.shade700),
                  ),
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: Text('Vô hiệu hóa (${_selectedIds.length})', style: const TextStyle(color: Colors.white)),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _keywordController,
              decoration: AdminTheme.inputDecoration('Tìm theo MSSV hoặc tên', prefixIcon: const Icon(Icons.search)),
              onSubmitted: (_) => _fetchStudents(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: AdminSuggestionField(
                    label: 'Năm nhập học',
                    controller: _startYearController,
                    onSearch: (kw) => _repo.getFilterSuggestions(type: 'startYear', keyword: kw),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdminSuggestionField(
                    label: 'Lớp',
                    controller: _classNameController,
                    onSearch: (kw) => _repo.getFilterSuggestions(type: 'className', keyword: kw),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminSuggestionField(
              label: 'Khoa',
              controller: _facultyController,
              onSearch: (kw) => _repo.getFilterSuggestions(type: 'faculty', keyword: kw),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedStatus,
              decoration: AdminTheme.inputDecoration('Trạng thái'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                ...studentStatusOptions.map(
                  (s) => DropdownMenuItem<String?>(value: s, child: Text(studentStatusLabel(s))),
                ),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: AdminTheme.primaryButtonStyle(),
                    onPressed: _fetchStudents,
                    child: const Text('Áp dụng bộ lọc', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: AdminTheme.outlinedButtonStyle(),
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _students.isEmpty
                    ? const Center(child: Text('Không có sinh viên', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _students[index];
                          final id = (s['id'] as num).toInt();
                          final selected = _selectedIds.contains(id);

                          return Material(
                            color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_selectionMode) {
                                  _toggleSelect(id);
                                } else {
                                  _openDetail(s);
                                }
                              },
                              onLongPress: () {
                                if (!_selectionMode) {
                                  _enterSelectionMode(id);
                                } else {
                                  _toggleSelect(id);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.border,
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
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  s['fullName']?.toString() ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                                ),
                                              ),
                                              if (s['status'] != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: studentStatusColor(s['status']?.toString()).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    studentStatusLabel(s['status']?.toString()),
                                                    style: TextStyle(fontSize: 10, color: studentStatusColor(s['status']?.toString()), fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'MSSV: ${s['studentCode'] ?? ''}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                          if (s['className'] != null || s['faculty'] != null)
                                            Text(
                                              '${s['className'] ?? ''} · ${s['faculty'] ?? ''}',
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!_selectionMode)
                                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
