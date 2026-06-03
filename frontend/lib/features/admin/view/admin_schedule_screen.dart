// admin_schedule_screen.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _dayLabels = {2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4', 5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7', 8: 'CN'};
const _periodLabels = {1: 'Ca 1 (07:00–09:15)', 2: 'Ca 2 (09:30–11:45)', 3: 'Ca 3 (12:30–14:45)', 4: 'Ca 4 (15:00–17:15)'};

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final _repo = AdminRepository();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _schedules = [];
  List<String> _academicYears = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  String? _filterSemester;
  String? _filterAcademicYear;

  // Import
  String? _importPath;
  String? _importFileName;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _fetchSchedules();

  Future<void> _loadData() async {
    await Future.wait([_fetchSchedules(), _fetchAcademicYears()]);
  }

  Future<void> _fetchAcademicYears() async {
    try {
      final years = await _repo.getScheduleAcademicYears();
      if (mounted) setState(() => _academicYears = years);
    } catch (_) {}
  }

  Future<void> _fetchSchedules() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAdminSchedules(
        keyword: _searchCtrl.text,
        semester: _filterSemester,
        academicYear: _filterAcademicYear,
      );
      if (!mounted) return;
      setState(() => _schedules = list);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách lịch học');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _filterSemester = null;
      _filterAcademicYear = null;
      _searchCtrl.clear();
    });
    _fetchSchedules();
  }

  // ── Selection mode ────────────────────────────────────────────────────────

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

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _schedules.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(_schedules.map((s) => (s['scheduleId'] as num).toInt()));
        _selectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await _showConfirmDialog(
      title: 'Xóa lịch học',
      content: 'Xóa ${_selectedIds.length} lịch học đã chọn?',
    );
    if (confirm != true) return;
    try {
      await _repo.softDeleteAdminSchedulesBulk(_selectedIds.toList());
      _showSnack('Đã xóa ${_selectedIds.length} lịch học');
      _cancelSelection();
      _fetchSchedules();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  // ── Import Excel ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null) {
      setState(() {
        _importPath = result.files.single.path;
        _importFileName = result.files.single.name;
      });
    }
  }

  Future<void> _previewAndImport() async {
    if (_importPath == null) {
      _showSnack('Hãy chọn file Excel lịch học');
      return;
    }
    try {
      final preview = await _repo.previewScheduleExcel(_importPath!);
      if (!mounted) return;
      final confirmed = await _showImportPreviewDialog(preview);
      if (confirmed != true) return;
      final result = await _repo.importScheduleExcel(_importPath!);
      final data = result['data'] as Map? ?? result;
      _showSnack('Import thành công ${data['successCount'] ?? 0} lịch học');
      setState(() { _importPath = null; _importFileName = null; });
      _fetchSchedules();
      _fetchAcademicYears();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Import thất bại');
    }
  }

  Future<bool?> _showImportPreviewDialog(Map<String, dynamic> preview) {
    if (preview.containsKey('error')) {
      _showSnack(preview['error'].toString());
      return Future.value(false);
    }
    final rows = (preview['rows'] as List? ?? []).cast<Map>();
    final validCount = preview['validCount'] as int? ?? 0;
    final invalidCount = preview['invalidCount'] as int? ?? 0;
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _ImportPreviewDialog(
          title: 'Preview import lịch học',
          validCount: validCount,
          invalidCount: invalidCount,
          columns: const ['Dòng', 'Mã MH', 'Tên MH', 'TH?', 'HK', 'Năm học', 'Thứ', 'Ca', 'Phòng', 'GV', 'Trạng thái'],
          rows: rows.map((r) {
            final valid = r['valid'] == true;
            return _PreviewRow(
              cells: [
                r['row']?.toString() ?? '',
                r['courseCode']?.toString() ?? '',
                r['courseName']?.toString() ?? '',
                r['isLab'] == true ? 'TH' : 'LT',
                r['semester']?.toString() ?? '',
                r['academicYear']?.toString() ?? '',
                r['dayOfWeek']?.toString() ?? '',
                r['period']?.toString() ?? '',
                r['room']?.toString() ?? '',
                r['lecturer']?.toString() ?? '',
                valid ? '✓ Hợp lệ' : '✗ ${r['error'] ?? ''}',
              ],
              isValid: valid,
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Group by semester/year ────────────────────────────────────────────────

  Map<String, List<Map<String, dynamic>>> _groupedSchedules() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final s in _schedules) {
      final key = 'HK ${s['semester']} — ${s['academicYear']}';
      groups.putIfAbsent(key, () => []).add(s);
    }
    return groups;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _selectionMode ? _selectionAppBar() : _normalAppBar(),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openScheduleForm(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm lịch học', style: TextStyle(color: Colors.white)),
            ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildImportBar(),
          _buildStatsBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  AppBar _normalAppBar() => AdminTheme.appBar(context, 'Quản lý lịch học');

  AppBar _selectionAppBar() => AppBar(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancelSelection),
    title: Text('Đã chọn ${_selectedIds.length}'),
    actions: [
      TextButton(
        onPressed: _toggleSelectAll,
        child: Text(
          _selectedIds.length == _schedules.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Xóa đã chọn',
        onPressed: _deleteSelected,
      ),
    ],
  );

  Widget _buildFilterBar() {
    final hasFilter = _filterSemester != null || _filterAcademicYear != null || _searchCtrl.text.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            decoration: AdminTheme.inputDecoration(
              'Tìm môn học theo mã hoặc tên...',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          // Filters row
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Học kỳ',
                  value: _filterSemester,
                  items: const ['1', '2', '3'],
                  itemLabel: (v) => 'HK $v',
                  onChanged: (v) { setState(() => _filterSemester = v); _fetchSchedules(); },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Năm học',
                  value: _filterAcademicYear,
                  items: _academicYears,
                  onChanged: (v) { setState(() => _filterAcademicYear = v); _fetchSchedules(); },
                ),
              ),
              if (hasFilter) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.outlined(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Reset bộ lọc',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _importFileName ?? 'Chưa chọn file Excel (course_code, is_lab, semester, academic_year, day_of_week, period, room, lecturer, start_date, end_date)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _importFileName != null ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: AdminTheme.outlinedButtonStyle(),
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file, size: 16),
            label: const Text('Chọn'),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: AdminTheme.primaryButtonStyle(),
            onPressed: _previewAndImport,
            icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
            label: const Text('Import', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_schedules.length} lịch học',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_filterSemester != null || _filterAcademicYear != null ||
                      _searchCtrl.text.isNotEmpty) ...[
                    const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                    const Text(
                      'đang lọc',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('Chưa có lịch học nào', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final groups = _groupedSchedules();
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        // Sort by academicYear desc, semester desc
        final aYear = a.split('— ').last;
        final bYear = b.split('— ').last;
        final cmp = bYear.compareTo(aYear);
        if (cmp != 0) return cmp;
        return b.compareTo(a);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final key = sortedKeys[i];
        final items = groups[key]!;
        return _ScheduleGroup(
          groupLabel: key,
          items: items,
          selectionMode: _selectionMode,
          selectedIds: _selectedIds,
          onLongPress: _enterSelectionMode,
          onTap: (id) {
            if (_selectionMode) {
              _toggleSelect(id);
            } else {
              _openScheduleDetail(id);
            }
          },
          onToggleSelect: _toggleSelect,
        );
      },
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openScheduleForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(repo: _repo),
    );
    if (created == true) {
      _fetchSchedules();
      _fetchAcademicYears();
    }
  }

  Future<void> _openScheduleDetail(int scheduleId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminScheduleDetailScreen(scheduleId: scheduleId, repo: _repo)),
    );
    if (changed == true) {
      _fetchSchedules();
      _fetchAcademicYears();
    }
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog({required String title, required String content}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Group (group by semester/year)
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleGroup extends StatelessWidget {
  final String groupLabel;
  final List<Map<String, dynamic>> items;
  final bool selectionMode;
  final Set<int> selectedIds;
  final void Function(int) onLongPress;
  final void Function(int) onTap;
  final void Function(int) onToggleSelect;

  const _ScheduleGroup({
    required this.groupLabel,
    required this.items,
    required this.selectionMode,
    required this.selectedIds,
    required this.onLongPress,
    required this.onTap,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$groupLabel  •  ${items.length} lịch',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        ...items.map((s) {
          final id = (s['scheduleId'] as num).toInt();
          final selected = selectedIds.contains(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScheduleCard(
              data: s,
              selected: selected,
              selectionMode: selectionMode,
              onLongPress: () => onLongPress(id),
              onTap: () => onTap(id),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.data,
    required this.selected,
    required this.selectionMode,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLab = data['isLab'] == true;
    final dayOfWeek = (data['dayOfWeek'] as num?)?.toInt() ?? 2;
    final period = (data['period'] as num?)?.toInt() ?? 1;
    final studentCount = (data['studentCount'] as num?)?.toInt() ?? 0;
    final periodStart = data['periodStart']?.toString() ?? '';
    final periodEnd = data['periodEnd']?.toString() ?? '';

    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Left: day/period badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isLab
                      ? Colors.orange.shade50
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLab ? Colors.orange.shade200 : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayLabels[dayOfWeek] ?? 'T$dayOfWeek',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLab ? Colors.orange.shade700 : AppColors.primary,
                      ),
                    ),
                    Text(
                      'Ca $period',
                      style: TextStyle(
                        fontSize: 10,
                        color: isLab ? Colors.orange.shade600 : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Middle: info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['courseName']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLab ? Colors.orange.shade100 : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLab ? 'TH' : 'LT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLab ? Colors.orange.shade700 : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['courseCode']} · ${data['semester'] != null ? 'HK${data['semester']}' : ''} ${data['academicYear'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (data['room'] != null && data['room'].toString().isNotEmpty) ...[
                          const Icon(Icons.room_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(data['room'].toString(),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                        ],
                        const Icon(Icons.access_time_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('$periodStart–$periodEnd',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Spacer(),
                        const Icon(Icons.people_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('$studentCount SV',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (data['lecturer'] != null && data['lecturer'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                data['lecturer'].toString(),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Right: checkbox or chevron
              if (selectionMode)
                Checkbox(
                  value: selected,
                  activeColor: AppColors.primary,
                  onChanged: (_) => onTap(),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminScheduleDetailScreen extends StatefulWidget {
  final int scheduleId;
  final AdminRepository repo;

  const AdminScheduleDetailScreen({super.key, required this.scheduleId, required this.repo});

  @override
  State<AdminScheduleDetailScreen> createState() => _AdminScheduleDetailScreenState();
}

class _AdminScheduleDetailScreenState extends State<AdminScheduleDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final data = await widget.repo.getAdminScheduleDetail(widget.scheduleId);
      if (mounted) setState(() => _detail = data);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được thông tin lịch học');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editSchedule() async {
    if (_detail == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(repo: widget.repo, existing: _detail),
    );
    if (updated == true) {
      _loadDetail();
    }
  }

  Future<void> _deleteSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa lịch học'),
        content: const Text('Bạn chắc chắn muốn xóa lịch học này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.repo.softDeleteAdminSchedule(widget.scheduleId);
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  Future<void> _manageStudents() async {
    if (_detail == null) return;
    final currentStudents = (_detail!['students'] as List? ?? [])
        .cast<Map>()
        .map((s) => (s['studentId'] as num).toInt())
        .toList();
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentPickerScreen(
          repo: widget.repo,
          scheduleId: widget.scheduleId,
          currentStudentIds: currentStudents,
        ),
      ),
    );
    if (updated == true) {
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AdminTheme.appBar(
          context,
          'Chi tiết lịch học',
          actions: [
            if (_detail != null) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Chỉnh sửa',
                onPressed: _editSchedule,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Xóa lịch học',
                onPressed: _deleteSchedule,
              ),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _detail == null
                ? const Center(child: Text('Không tìm thấy lịch học'))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final isLab = d['isLab'] == true;
    final dayOfWeek = (d['dayOfWeek'] as num?)?.toInt() ?? 2;
    final period = (d['period'] as num?)?.toInt() ?? 1;
    final students = (d['students'] as List? ?? []).cast<Map>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Course info card
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d['courseName']?.toString() ?? '',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TypeBadge(isLab: isLab),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(icon: Icons.code, label: 'Mã môn', value: d['courseCode']?.toString() ?? ''),
              _InfoRow(icon: Icons.star_outline, label: 'Tín chỉ', value: '${d['credits'] ?? ''}'),
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'Học kỳ', value: 'HK${d['semester']} — ${d['academicYear']}'),
              if (d['startDate'] != null)
                _InfoRow(icon: Icons.date_range_outlined, label: 'Thời gian',
                    value: '${d['startDate']} → ${d['endDate'] ?? ''}'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Schedule info card
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminTheme.sectionTitle('Thông tin lịch học'),
              _InfoRow(icon: Icons.today_outlined, label: 'Thứ', value: _dayLabels[dayOfWeek] ?? 'T$dayOfWeek'),
              _InfoRow(icon: Icons.access_time_outlined, label: 'Ca học',
                  value: 'Ca $period (${d['periodStart']} – ${d['periodEnd']})'),
              if (d['room'] != null && d['room'].toString().isNotEmpty)
                _InfoRow(icon: Icons.room_outlined, label: 'Phòng học', value: d['room'].toString()),
              if (d['lecturer'] != null && d['lecturer'].toString().isNotEmpty)
                _InfoRow(icon: Icons.person_outline, label: 'Giảng viên', value: d['lecturer'].toString()),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Students card
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: AdminTheme.sectionTitle('Danh sách sinh viên (${students.length})')),
                  TextButton.icon(
                    onPressed: _manageStudents,
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18, color: AppColors.primary),
                    label: const Text('Quản lý', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có sinh viên trong lịch này',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ...students.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: i < students.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text('${i + 1}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['fullName']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text(s['studentCode']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Form (create / edit) as BottomSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleFormSheet extends StatefulWidget {
  final AdminRepository repo;
  final Map<String, dynamic>? existing; // null = create mode

  const _ScheduleFormSheet({required this.repo, this.existing});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  // Course search
  final _courseSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _courseOptions = [];
  Map<String, dynamic>? _selectedCourse;

  // Fields
  final _semesterCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _lecturerCtrl = TextEditingController();
  int? _dayOfWeek;
  int? _period;
  bool _isLab = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _selectedCourse = {
        'id': d['courseId'],
        'courseCode': d['courseCode'],
        'courseName': d['courseName'],
        'credits': d['credits'],
      };
      _courseSearchCtrl.text = '${d['courseCode']} — ${d['courseName']}';
      _semesterCtrl.text = d['semester']?.toString() ?? '';
      _academicYearCtrl.text = d['academicYear']?.toString() ?? '';
      _startDateCtrl.text = d['startDate']?.toString() ?? '';
      _endDateCtrl.text = d['endDate']?.toString() ?? '';
      _roomCtrl.text = d['room']?.toString() ?? '';
      _lecturerCtrl.text = d['lecturer']?.toString() ?? '';
      _dayOfWeek = (d['dayOfWeek'] as num?)?.toInt();
      _period = (d['period'] as num?)?.toInt();
      _isLab = d['isLab'] == true;
    }
  }

  @override
  void dispose() {
    _courseSearchCtrl.dispose();
    _semesterCtrl.dispose();
    _academicYearCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _roomCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCourses(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _courseOptions = []);
      return;
    }
    try {
      final all = await widget.repo.getCourses();
      final lower = q.toLowerCase();
      setState(() {
        _courseOptions = all.where((c) {
          final code = (c['courseCode'] ?? '').toString().toLowerCase();
          final name = (c['courseName'] ?? '').toString().toLowerCase();
          return code.contains(lower) || name.contains(lower);
        }).take(10).toList();
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_selectedCourse == null) { _showSnack('Vui lòng chọn môn học'); return; }
    if (_semesterCtrl.text.trim().isEmpty) { _showSnack('Vui lòng nhập học kỳ'); return; }
    if (_academicYearCtrl.text.trim().isEmpty) { _showSnack('Vui lòng nhập năm học'); return; }
    if (_dayOfWeek == null) { _showSnack('Vui lòng chọn thứ'); return; }
    if (_period == null) { _showSnack('Vui lòng chọn ca học'); return; }

    setState(() => _saving = true);
    try {
      final payload = {
        'courseId': _selectedCourse!['id'],
        'isLab': _isLab,
        'semester': _semesterCtrl.text.trim(),
        'academicYear': _academicYearCtrl.text.trim(),
        'startDate': _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
        'endDate': _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
        'room': _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
        'lecturer': _lecturerCtrl.text.trim().isEmpty ? null : _lecturerCtrl.text.trim(),
        'dayOfWeek': _dayOfWeek,
        'period': _period,
      };

      if (widget.existing != null) {
        await widget.repo.updateAdminSchedule(
            (widget.existing!['scheduleId'] as num).toInt(), payload);
        _showSnack('Cập nhật lịch học thành công');
      } else {
        await widget.repo.createAdminSchedule(payload);
        _showSnack('Thêm lịch học thành công');
      }
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    // Đẩy content lên khi bàn phím xuất hiện
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Chỉnh sửa lịch học' : 'Thêm lịch học mới',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Môn học ──────────────────────────────────────────────
                  AdminTheme.sectionTitle('Môn học'),
                  if (isEdit) ...[
                    // Edit mode: chỉ hiển thị thông tin môn học, không cho đổi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedCourse?['courseCode'] ?? ''} — ${_selectedCourse?['courseName'] ?? ''}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                if (_selectedCourse?['credits'] != null)
                                  Text('${_selectedCourse!['credits']} tín chỉ',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Create mode: search môn học
                    TextField(
                      controller: _courseSearchCtrl,
                      decoration: AdminTheme.inputDecoration(
                        'Tìm môn học theo mã hoặc tên',
                        prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                      ),
                      onChanged: _searchCourses,
                    ),
                    if (_courseOptions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                        ),
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _courseOptions.length,
                          itemBuilder: (_, i) {
                            final c = _courseOptions[i];
                            return ListTile(
                              dense: true,
                              title: Text('${c['courseCode']} — ${c['courseName']}'),
                              subtitle: Text('${c['credits']} tín chỉ'),
                              onTap: () {
                                setState(() {
                                  _selectedCourse = c;
                                  _courseSearchCtrl.text = '${c['courseCode']} — ${c['courseName']}';
                                  _courseOptions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    if (_selectedCourse != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_selectedCourse!['courseCode']} — ${_selectedCourse!['courseName']}',
                                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),

                  // ── isLab toggle ──────────────────────────────────────────
                  Row(
                    children: [
                      const Text('Loại:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      _TypeToggle(
                        value: _isLab,
                        onChanged: (v) => setState(() => _isLab = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Học kỳ ───────────────────────────────────────────────
                  AdminTheme.sectionTitle('Thông tin học kỳ'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _semesterCtrl.text.isEmpty ? null : _semesterCtrl.text,
                          decoration: AdminTheme.inputDecoration('Học kỳ'),
                          items: ['1', '2', '3']
                              .map((s) => DropdownMenuItem(value: s, child: Text('HK $s')))
                              .toList(),
                          onChanged: (v) => setState(() => _semesterCtrl.text = v ?? ''),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _academicYearCtrl,
                          decoration: AdminTheme.inputDecoration('Năm học', hint: '2024-2025'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _DateField(label: 'Ngày bắt đầu', controller: _startDateCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: _DateField(label: 'Ngày kết thúc', controller: _endDateCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Lịch học ─────────────────────────────────────────────
                  AdminTheme.sectionTitle('Lịch học'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _dayOfWeek,
                          decoration: AdminTheme.inputDecoration('Thứ'),
                          isExpanded: true,
                          items: _dayLabels.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _dayOfWeek = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _period,
                          decoration: AdminTheme.inputDecoration('Ca học'),
                          isExpanded: true,
                          items: _periodLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _period = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _roomCtrl,
                    decoration: AdminTheme.inputDecoration('Phòng học',
                        prefixIcon: const Icon(Icons.room_outlined, size: 20)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lecturerCtrl,
                    decoration: AdminTheme.inputDecoration('Giảng viên',
                        prefixIcon: const Icon(Icons.person_outline, size: 20)),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: AdminTheme.primaryButtonStyle(),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEdit ? 'Lưu thay đổi' : 'Thêm lịch học',
                              style: const TextStyle(fontSize: 15, color: Colors.white),
                            ),
                    ),
                  ),
                  // Extra space khi bàn phím xuất hiện
                  SizedBox(height: bottomInset > 0 ? 16 : 0),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Picker Screen
// ─────────────────────────────────────────────────────────────────────────────

class _StudentPickerScreen extends StatefulWidget {
  final AdminRepository repo;
  final int scheduleId;
  final List<int> currentStudentIds;

  const _StudentPickerScreen({
    required this.repo,
    required this.scheduleId,
    required this.currentStudentIds,
  });

  @override
  State<_StudentPickerScreen> createState() => _StudentPickerScreenState();
}

class _StudentPickerScreenState extends State<_StudentPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filtered = [];
  late Set<int> _selectedIds;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.currentStudentIds);
    _loadStudents();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final list = await widget.repo.getAllStudentsForSchedule();
      if (!mounted) return;
      setState(() {
        _allStudents = list;
        _filtered = list;
      });
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách sinh viên');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allStudents
          : _allStudents.where((s) {
              final name = (s['fullName'] ?? '').toString().toLowerCase();
              final code = (s['studentCode'] ?? '').toString().toLowerCase();
              return name.contains(q) || code.contains(q);
            }).toList();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateScheduleStudents(widget.scheduleId, _selectedIds.toList());
      _showSnack('Đã cập nhật danh sách sinh viên');
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Cập nhật thất bại');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(
        context,
        'Quản lý sinh viên trong lịch',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('Xác nhận', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: AdminTheme.inputDecoration(
                'Tìm theo tên hoặc MSSV...',
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
            ),
          ),
          // Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  'Đã chọn ${_selectedIds.length} / ${_allStudents.length} sinh viên',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _allStudents.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(
                            _allStudents.map((s) => (s['id'] as num).toInt()));
                      }
                    });
                  },
                  child: Text(
                    _selectedIds.length == _allStudents.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                    style: const TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? const Center(child: Text('Không tìm thấy sinh viên'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final s = _filtered[i];
                          final id = (s['id'] as num).toInt();
                          final isInSchedule = _selectedIds.contains(id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isInSchedule
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isInSchedule ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Icon(
                                isInSchedule ? Icons.check : Icons.person_outline,
                                size: 18,
                                color: isInSchedule ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                            title: Text(
                              s['fullName']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isInSchedule ? FontWeight.w600 : FontWeight.normal,
                                color: isInSchedule ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              s['studentCode']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            trailing: Checkbox(
                              value: isInSchedule,
                              activeColor: AppColors.primary,
                              onChanged: (_) {
                                setState(() {
                                  if (isInSchedule) {
                                    _selectedIds.remove(id);
                                  } else {
                                    _selectedIds.add(id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                if (isInSchedule) {
                                  _selectedIds.remove(id);
                                } else {
                                  _selectedIds.add(id);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String Function(String)? itemLabel;
  final void Function(String?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      isExpanded: true,
      decoration: AdminTheme.inputDecoration(label),
      items: [
        DropdownMenuItem<String>(value: null, child: Text('Tất cả', style: TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        ...items.map((v) => DropdownMenuItem(value: v, child: Text(itemLabel != null ? itemLabel!(v) : v, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: onChanged,
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _toggleBtn(label: 'Lý thuyết', active: !value, onTap: () => onChanged(false)),
        const SizedBox(width: 8),
        _toggleBtn(label: 'Thực hành', active: value, onTap: () => onChanged(true), isLab: true),
      ],
    );
  }

  Widget _toggleBtn({required String label, required bool active, required VoidCallback onTap, bool isLab = false}) {
    final color = isLab ? Colors.orange.shade700 : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : AppColors.border, width: active ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isLab;
  const _TypeBadge({required this.isLab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLab ? Colors.orange.shade100 : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLab ? 'Thực hành' : 'Lý thuyết',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isLab ? Colors.orange.shade700 : AppColors.primary,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
}

class _DateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _DateField({required this.label, required this.controller});

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  Future<void> _pick() async {
    final now = DateTime.now();
    DateTime? initial;
    try {
      initial = DateTime.parse(widget.controller.text);
    } catch (_) {
      initial = now;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => widget.controller.text = formatted);
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        readOnly: true,
        onTap: _pick,
        decoration: AdminTheme.inputDecoration(
          widget.label,
          hint: 'yyyy-MM-dd',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Preview Dialog (reused from academic screen pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewRow {
  final List<String> cells;
  final bool isValid;
  const _PreviewRow({required this.cells, required this.isValid});
}

class _ImportPreviewDialog extends StatelessWidget {
  final String title;
  final int validCount;
  final int invalidCount;
  final List<String> columns;
  final List<_PreviewRow> rows;

  const _ImportPreviewDialog({
    required this.title,
    required this.validCount,
    required this.invalidCount,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _CountChip(label: '$validCount hợp lệ', color: AppColors.primary),
              const SizedBox(width: 8),
              if (invalidCount > 0)
                _CountChip(label: '$invalidCount lỗi', color: Colors.red.shade700),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 48,
                  columnSpacing: 12,
                  headingRowColor: WidgetStateProperty.resolveWith((_) => AppColors.surface),
                  columns: columns
                      .map((c) => DataColumn(
                            label: Text(c,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ))
                      .toList(),
                  rows: rows
                      .map((r) => DataRow(
                            color: WidgetStateProperty.resolveWith((_) =>
                                r.isValid ? null : Colors.red.shade50),
                            cells: r.cells
                                .map((cell) => DataCell(
                                      Text(cell,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cell.startsWith('✗')
                                                ? Colors.red.shade700
                                                : cell.startsWith('✓')
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                          )),
                                    ))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: AdminTheme.primaryButtonStyle(),
                onPressed: validCount > 0
                    ? () => Navigator.pop(context, true)
                    : null,
                child: Text(
                  'Import $validCount lịch học',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      );
}
