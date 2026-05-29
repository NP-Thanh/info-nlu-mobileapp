import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../utils/student_status.dart';
import '../widgets/admin_widgets.dart';
import 'admin_student_form_screen.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  final int studentId;

  const AdminStudentDetailScreen({super.key, required this.studentId});

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late final TabController _tabController;

  Map<String, dynamic>? _student;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final data = await _repo.getStudentDetail(widget.studentId);
      if (!mounted) return;
      setState(() => _student = data);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được thông tin sinh viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEdit() async {
    if (_student == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminStudentFormScreen(student: _student)),
    );
    if (updated == true) {
      _changed = true;
      _loadDetail();
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(
            _student?['fullName']?.toString() ?? 'Chi tiết sinh viên',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Lịch học'),
              Tab(text: 'Bảng điểm'),
            ],
          ),
        ),
        floatingActionButton: _tabController.index == 0
            ? null
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _student == null
                ? const Center(child: Text('Không tìm thấy sinh viên'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _InfoTab(student: _student!, onEdit: _openEdit),
                      _ScheduleTab(studentId: widget.studentId, repo: _repo, onChanged: () => _changed = true),
                      _GradesTab(studentId: widget.studentId, repo: _repo),
                    ],
                  ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onEdit;

  const _InfoTab({required this.student, required this.onEdit});

  Widget _row(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            Expanded(child: Text(value ?? '—', style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminTheme.infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      (student['fullName']?.toString().isNotEmpty == true)
                          ? student['fullName'].toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['fullName']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('MSSV: ${student['studentCode'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row('Email', student['email']?.toString()),
              _row('SĐT', student['phone']?.toString()),
              _row('Giới tính', student['gender']?.toString()),
              _row('Ngày sinh', student['dateOfBirth']?.toString()),
              _row('CCCD', student['cccd']?.toString()),
              _row('Dân tộc', student['ethnicity']?.toString()),
              _row('Tôn giáo', student['religion']?.toString()),
              _row('Quốc tịch', student['nationality']?.toString()),
              _row('Nơi sinh', student['placeOfBirth']?.toString()),
              _row('Năm nhập học', student['startYear']?.toString()),
              _row('Năm kết thúc', student['endYear']?.toString()),
              _row('Trạng thái', studentStatusLabel(student['status']?.toString())),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminTheme.sectionTitle('Chương trình đào tạo'),
        AdminTheme.infoCard(
          child: Column(
            children: [
              _row('Khoa', student['faculty']?.toString()),
              _row('Ngành', student['major']?.toString()),
              _row('Chuyên ngành', student['specialization']?.toString()),
              _row('Lớp', student['className']?.toString()),
              _row('Hệ đào tạo', student['educationType']?.toString()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: AdminTheme.primaryButtonStyle(),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTab extends StatefulWidget {
  final int studentId;
  final AdminRepository repo;
  final VoidCallback onChanged;

  const _ScheduleTab({required this.studentId, required this.repo, required this.onChanged});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  Map<String, dynamic>? _schedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.repo.getStudentLatestSchedule(widget.studentId);
      if (!mounted) return;
      setState(() => _schedule = data);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được lịch học');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dayLabel(int? day) {
    return switch (day) {
      2 => 'Thứ 2',
      3 => 'Thứ 3',
      4 => 'Thứ 4',
      5 => 'Thứ 5',
      6 => 'Thứ 6',
      7 => 'Thứ 7',
      8 => 'Chủ nhật',
      _ => '—',
    };
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

  Future<void> _editItem(Map<String, dynamic> item) async {
    final room = TextEditingController(text: item['room']?.toString() ?? '');
    final lecturer = TextEditingController(text: item['lecturer']?.toString() ?? '');
    final day = TextEditingController(text: item['dayOfWeek']?.toString() ?? '');
    final period = TextEditingController(text: item['period']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa lịch học'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: room, decoration: AdminTheme.inputDecoration('Phòng')),
              const SizedBox(height: 8),
              TextField(controller: lecturer, decoration: AdminTheme.inputDecoration('Giảng viên')),
              const SizedBox(height: 8),
              TextField(controller: day, keyboardType: TextInputType.number, decoration: AdminTheme.inputDecoration('Thứ (2-8)')),
              const SizedBox(height: 8),
              TextField(controller: period, keyboardType: TextInputType.number, decoration: AdminTheme.inputDecoration('Ca (1-4)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: AdminTheme.primaryButtonStyle(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await widget.repo.updateSchedule((item['scheduleId'] as num).toInt(), {
        'room': room.text.trim(),
        'lecturer': lecturer.text.trim(),
        'dayOfWeek': int.tryParse(day.text.trim()),
        'period': int.tryParse(period.text.trim()),
      });
      widget.onChanged();
      _load();
      _showSnack('Đã cập nhật lịch học');
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Cập nhật thất bại');
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa lịch học'),
        content: Text('Xóa buổi học ${item['courseName'] ?? ''}?'),
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
      await widget.repo.deleteSchedule((item['scheduleId'] as num).toInt());
      widget.onChanged();
      _load();
      _showSnack('Đã xóa lịch học');
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    final items = (_schedule?['items'] as List<dynamic>?) ?? [];
    final semester = _schedule?['semester'];
    final year = _schedule?['academicYear'];
    final startDate = _formatDate(_schedule?['startDate']?.toString());
    final endDate = _formatDate(_schedule?['endDate']?.toString());

    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw as Map);
      final day = (item['dayOfWeek'] as num?)?.toInt() ?? 0;
      byDay.putIfAbsent(day, () => []).add(item);
    }
    final sortedDays = byDay.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminTheme.infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          semester != null ? 'Học kỳ $semester · $year' : 'Chưa có lịch học',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (semester != null) ...[
                          const SizedBox(height: 4),
                          Text('Bắt đầu: $startDate', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text('Kết thúc: $endDate', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Không có lịch học')))
        else
          ...sortedDays.map((day) {
            final dayItems = byDay[day]!..sort((a, b) => ((a['period'] as num?) ?? 0).compareTo((b['period'] as num?) ?? 0));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(_dayLabel(day), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                ...dayItems.map((item) => _ScheduleLessonCard(
                      item: item,
                      dayLabel: _dayLabel(day),
                      formatDate: _formatDate,
                      onEdit: () => _editItem(item),
                      onDelete: () => _deleteItem(item),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }),
      ],
    );
  }
}

class _ScheduleLessonCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String dayLabel;
  final String Function(String?) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleLessonCard({
    required this.item,
    required this.dayLabel,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _isLab {
    final v = item['isLab'];
    if (v is bool) return v;
    if (v is num) return v == 1;
    return v?.toString().toLowerCase() == 'true' || v?.toString() == '1';
  }

  static const _labColor = Color(0xFFE65100);
  static const _labBg = Color(0xFFFFF3E0);

  @override
  Widget build(BuildContext context) {
    final accent = _isLab ? _labColor : AppColors.primary;
    final headerBg = _isLab ? _labBg : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isLab ? _labColor.withValues(alpha: 0.45) : AppColors.border, width: _isLab ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['courseName']?.toString() ?? '',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _isLab ? _labColor : AppColors.textPrimary),
                  ),
                ),
                if (_isLab)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _labColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _labColor.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Thực hành', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _labColor)),
                  ),
                Text(
                  'Ca ${item['period']}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['courseCode']} · ${item['credits']} tín chỉ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                _scheduleRow(Icons.access_time, '${item['periodStart']} – ${item['periodEnd']}', accent),
                _scheduleRow(Icons.meeting_room_outlined, 'Phòng: ${item['room'] ?? '—'}', accent),
                _scheduleRow(Icons.person_outline, 'GV: ${item['lecturer'] ?? '—'}', accent),
                _scheduleRow(Icons.date_range_outlined, 'Môn: ${formatDate(item['enrollmentStartDate']?.toString())} → ${formatDate(item['enrollmentEndDate']?.toString())}', accent),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                      label: Text('Sửa', style: TextStyle(color: accent)),
                    ),
                    TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), label: const Text('Xóa', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.75)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _GradesTab extends StatefulWidget {
  final int studentId;
  final AdminRepository repo;

  const _GradesTab({required this.studentId, required this.repo});

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  List<Map<String, dynamic>> _semesters = [];
  String? _selectedTerm;
  Map<String, dynamic>? _grades;
  bool _loadingSemesters = true;
  bool _loadingGrades = false;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() => _loadingSemesters = true);
    try {
      final list = await widget.repo.getStudentGradeSemesters(widget.studentId);
      if (!mounted) return;
      setState(() {
        _semesters = list;
        if (list.isNotEmpty) {
          final first = list.first;
          _selectedTerm = '${first['semester']}|${first['academicYear']}';
        }
      });
      if (list.isNotEmpty) _loadGrades();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được học kỳ');
    } finally {
      if (mounted) setState(() => _loadingSemesters = false);
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedTerm == null) return;
    final parts = _selectedTerm!.split('|');
    if (parts.length != 2) return;

    setState(() => _loadingGrades = true);
    try {
      final data = await widget.repo.getStudentGrades(
        studentId: widget.studentId,
        academicYear: parts[1],
        semester: parts[0],
      );
      if (!mounted) return;
      setState(() => _grades = data);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được bảng điểm');
    } finally {
      if (mounted) setState(() => _loadingGrades = false);
    }
  }

  Widget _gradeChip(String label, dynamic value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: highlight ? AppColors.primary : AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value?.toString() ?? '—',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: highlight ? AppColors.primary : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSemesters) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final gradeItems = (_grades?['grades'] as List<dynamic>?) ?? [];
    final summary = _grades?['semesterSummary'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedTerm,
          decoration: AdminTheme.inputDecoration('Chọn học kỳ'),
          items: _semesters.map((s) {
            final sem = s['semester']?.toString() ?? '';
            final year = s['academicYear']?.toString() ?? '';
            final value = '$sem|$year';
            return DropdownMenuItem(value: value, child: Text('HK $sem · $year'));
          }).toList(),
          onChanged: (v) {
            setState(() => _selectedTerm = v);
            _loadGrades();
          },
        ),
        if (!_loadingGrades) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Điểm tổng kết', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          _SemesterSummaryText(summary: summary ?? const {}),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Điểm các môn học', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 8),
              if (gradeItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${gradeItems.length} môn',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (_loadingGrades)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (gradeItems.isEmpty)
          const Center(child: Text('Không có điểm cho học kỳ này'))
        else
          ...gradeItems.map((raw) {
            final g = Map<String, dynamic>.from(raw as Map);
            final passed = (g['result']?.toString() ?? '').toLowerCase().contains('pass');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['courseName']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${g['courseCode']} · ${g['credits']} tín chỉ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (passed ? AppColors.primary : Colors.red).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            g['result']?.toString() ?? '—',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: passed ? AppColors.primary : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _gradeChip('QT', g['processScore']),
                        _gradeChip('Thi', g['examScore']),
                        _gradeChip('TK 10', g['finalScore10'], highlight: true),
                        _gradeChip('TK 4', g['finalScore4']),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _SemesterSummaryText extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _SemesterSummaryText({required this.summary});

  String _fmt(dynamic v) => v == null ? '—' : v.toString();

  @override
  Widget build(BuildContext context) {
    return AdminTheme.infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng kết học kỳ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          // Hàng 1: Điểm học kỳ
          Row(
            children: [
              Expanded(child: _summaryItem('ĐTB HK (10)', _fmt(summary['gpa10']), highlight: true)),
              const SizedBox(width: 8),
              Expanded(child: _summaryItem('ĐTB HK (4)', _fmt(summary['gpa4']), highlight: true)),
              const SizedBox(width: 8),
              Expanded(child: _summaryItem('TC học kỳ', _fmt(summary['semesterCredits']))),
            ],
          ),
          const SizedBox(height: 8),
          // Hàng 2: Điểm tích lũy
          Row(
            children: [
              Expanded(child: _summaryItem('ĐTB TL (10)', _fmt(summary['cumulativeGpa10']))),
              const SizedBox(width: 8),
              Expanded(child: _summaryItem('ĐTB TL (4)', _fmt(summary['cumulativeGpa4']))),
              const SizedBox(width: 8),
              Expanded(child: _summaryItem('TC tích lũy', _fmt(summary['cumulativeCredits']))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: highlight ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
