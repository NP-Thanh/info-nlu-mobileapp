// admin_section_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _dayLabels = {2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4', 5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7', 8: 'CN'};
const _periodLabels = {
  1: 'Ca 1 (07:00–09:15)',
  2: 'Ca 2 (09:30–11:45)',
  3: 'Ca 3 (12:30–14:45)',
  4: 'Ca 4 (15:00–17:15)',
};

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen – danh sách học phần
// ─────────────────────────────────────────────────────────────────────────────

class AdminSectionScreen extends StatefulWidget {
  const AdminSectionScreen({super.key});

  @override
  State<AdminSectionScreen> createState() => _AdminSectionScreenState();
}

class _AdminSectionScreenState extends State<AdminSectionScreen> {
  final _repo = AdminRepository();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _sections = [];
  List<String> _academicYears = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  String? _filterSemester;
  String? _filterAcademicYear;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_fetchSections);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchSections(), _fetchAcademicYears()]);
  }

  Future<void> _fetchAcademicYears() async {
    try {
      final years = await _repo.getSectionAcademicYears();
      if (mounted) setState(() => _academicYears = years);
    } catch (_) {}
  }

  Future<void> _fetchSections() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getAdminSections(
        keyword: _searchCtrl.text,
        semester: _filterSemester,
        academicYear: _filterAcademicYear,
      );
      if (!mounted) return;
      setState(() => _sections = list);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách học phần', isError: true);
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
    _fetchSections();
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
      if (_selectedIds.length == _sections.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(_sections.map((s) => (s['sectionId'] as num).toInt()));
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa học phần'),
        content: Text('Xóa ${_selectedIds.length} học phần đã chọn?\nTất cả lịch học và đăng ký của sinh viên sẽ bị xóa.'),
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
      await _repo.deleteAdminSectionsBulk(_selectedIds.toList());
      _showSnack('Đã xóa ${_selectedIds.length} học phần');
      _cancelSelection();
      _loadData();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại', isError: true);
    }
  }

  // ── Import Excel học phần ─────────────────────────────────────────────────

  // ── Group by semester/year ────────────────────────────────────────────────

  Map<String, List<Map<String, dynamic>>> _groupedSections() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final s in _sections) {
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
              onPressed: _openSectionForm,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm học phần', style: TextStyle(color: Colors.white)),
            ),
      body: Column(
        children: [
          _buildFilterBar(),
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
              _selectedIds.length == _sections.length ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
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
          TextField(
            controller: _searchCtrl,
            decoration: AdminTheme.inputDecoration(
              'Tìm môn học theo mã hoặc tên...',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Học kỳ',
                  value: _filterSemester,
                  items: const ['1', '2', '3'],
                  itemLabel: (v) => 'HK $v',
                  onChanged: (v) {
                    setState(() => _filterSemester = v);
                    _fetchSections();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterDropdown(
                  label: 'Năm học',
                  value: _filterAcademicYear,
                  items: _academicYears,
                  onChanged: (v) {
                    setState(() => _filterAcademicYear = v);
                    _fetchSections();
                  },
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
                    '${_sections.length} học phần',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  if (_filterSemester != null || _filterAcademicYear != null || _searchCtrl.text.isNotEmpty) ...[
                    const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                    const Text('đang lọc',
                        style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
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
    if (_sections.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.class_outlined, size: 56, color: AppColors.border),
                  const SizedBox(height: 12),
                  const Text('Chưa có học phần nào', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final groups = _groupedSections();
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final aYear = a.split('— ').last;
        final bYear = b.split('— ').last;
        final cmp = bYear.compareTo(aYear);
        if (cmp != 0) return cmp;
        return b.compareTo(a);
      });

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, i) {
        final key = sortedKeys[i];
        final items = groups[key]!;
        return _SectionGroup(
          groupLabel: key,
          items: items,
          selectionMode: _selectionMode,
          selectedIds: _selectedIds,
          onLongPress: _enterSelectionMode,
          onTap: (id) {
            if (_selectionMode) {
              _toggleSelect(id);
            } else {
              _openSectionDetail(id);
            }
          },
          onToggleSelect: _toggleSelect,
        );
      },
    ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openSectionForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionFormSheet(repo: _repo),
    );
    if (created == true) _loadData();
  }

  Future<void> _openSectionDetail(int sectionId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminSectionDetailScreen(sectionId: sectionId, repo: _repo)),
    );
    if (changed == true) _loadData();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Group
// ─────────────────────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  final String groupLabel;
  final List<Map<String, dynamic>> items;
  final bool selectionMode;
  final Set<int> selectedIds;
  final void Function(int) onLongPress;
  final void Function(int) onTap;
  final void Function(int) onToggleSelect;

  const _SectionGroup({
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
              '$groupLabel  •  ${items.length} học phần',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
        ...items.map((s) {
          final id = (s['sectionId'] as num).toInt();
          final selected = selectedIds.contains(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SectionCard(
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
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _SectionCard({
    required this.data,
    required this.selected,
    required this.selectionMode,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLab = data['isLab'] == true;
    final studentCount = (data['studentCount'] as num?)?.toInt() ?? 0;
    final scheduleCount = (data['scheduleCount'] as num?)?.toInt() ?? 0;

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
              // Left badge: LT/TH
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLab ? Colors.orange.shade50 : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLab ? Colors.orange.shade200 : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    isLab ? 'TH' : 'LT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isLab ? Colors.orange.shade700 : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['courseName']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data['courseCode']} · HK${data['semester']} ${data['academicYear']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('$scheduleCount ca học',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('$studentCount SV',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
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
// Section Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminSectionDetailScreen extends StatefulWidget {
  final int sectionId;
  final AdminRepository repo;

  const AdminSectionDetailScreen({super.key, required this.sectionId, required this.repo});

  @override
  State<AdminSectionDetailScreen> createState() => _AdminSectionDetailScreenState();
}

class _AdminSectionDetailScreenState extends State<AdminSectionDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final data = await widget.repo.getAdminSectionDetail(widget.sectionId);
      if (mounted) setState(() => _detail = data);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được thông tin học phần', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editSection() async {
    if (_detail == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionEditSheet(
        repo: widget.repo,
        sectionId: widget.sectionId,
        detail: _detail!,
      ),
    );
    if (updated == true) _loadDetail();
  }

  Future<void> _deleteSection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa học phần'),
        content: const Text('Tất cả lịch học và đăng ký của sinh viên sẽ bị xóa. Tiếp tục?'),
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
      await widget.repo.deleteAdminSection(widget.sectionId);
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại', isError: true);
    }
  }

  Future<void> _addSchedule() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionScheduleFormSheet(
        repo: widget.repo,
        sectionId: widget.sectionId,
      ),
    );
    if (added == true) _loadDetail();
  }

  Future<void> _editSchedule(Map<dynamic, dynamic> sch) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionScheduleFormSheet(
        repo: widget.repo,
        sectionId: widget.sectionId,
        existing: Map<String, dynamic>.from(sch),
      ),
    );
    if (updated == true) _loadDetail();
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa ca học'),
        content: const Text('Xóa ca học này khỏi học phần?'),
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
      await widget.repo.deleteScheduleInSection(scheduleId);
      _showSnack('Đã xóa ca học');
      _loadDetail();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại', isError: true);
    }
  }

  Future<void> _manageStudents() async {
    if (_detail == null) return;
    final currentIds = (_detail!['students'] as List? ?? [])
        .cast<Map>()
        .map((s) => (s['studentId'] as num).toInt())
        .toList();
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _SectionStudentPickerScreen(
          repo: widget.repo,
          sectionId: widget.sectionId,
          currentStudentIds: currentIds,
        ),
      ),
    );
    if (updated == true) _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final isLab = d?['isLab'] == true;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          d != null ? '${d['courseCode']} — ${isLab ? 'TH' : 'LT'}' : 'Chi tiết học phần',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.border),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Lịch học'),
                  Tab(text: 'Sinh viên'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (d != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Chỉnh sửa học phần',
              onPressed: _editSection,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa học phần',
              onPressed: _deleteSection,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _detail == null
              ? const Center(child: Text('Không tìm thấy học phần'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScheduleTab(),
                    _buildStudentTab(),
                  ],
                ),
    );
  }

  Widget _buildScheduleTab() {
    final d = _detail!;
    final schedules = (d['schedules'] as List? ?? []).cast<Map>();
    final isLab = d['isLab'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d['courseName']?.toString() ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _TypeBadge(isLab: isLab),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.code, label: 'Mã môn', value: d['courseCode']?.toString() ?? ''),
              _InfoRow(icon: Icons.star_outline, label: 'Tín chỉ', value: '${d['credits'] ?? ''}'),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Học kỳ',
                  value: 'HK${d['semester']} — ${d['academicYear']}'),
              if (d['startDate'] != null)
                _InfoRow(
                    icon: Icons.date_range_outlined,
                    label: 'Thời gian',
                    value: '${d['startDate']} → ${d['endDate'] ?? ''}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Schedules card
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: AdminTheme.sectionTitle('Các ca học (${schedules.length})')),
                  TextButton.icon(
                    onPressed: _addSchedule,
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                    label: const Text('Thêm ca', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              if (schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có ca học nào. Nhấn "Thêm ca" để thêm.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                ...schedules.asMap().entries.map((entry) {
                  final i = entry.key;
                  final sch = entry.value;
                  final scheduleId = (sch['scheduleId'] as num).toInt();
                  final day = (sch['dayOfWeek'] as num?)?.toInt() ?? 2;
                  final period = (sch['period'] as num?)?.toInt() ?? 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: i < schedules.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_dayLabels[day] ?? 'T$day',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              Text('Ca $period',
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sch['periodStart']} – ${sch['periodEnd']}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              if (sch['room'] != null && sch['room'].toString().isNotEmpty)
                                Text('Phòng: ${sch['room']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              if (sch['lecturer'] != null && sch['lecturer'].toString().isNotEmpty)
                                Text('GV: ${sch['lecturer']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                          onPressed: () => _editSchedule(sch),
                          tooltip: 'Sửa',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                          onPressed: () => _deleteSchedule(scheduleId),
                          tooltip: 'Xóa',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

  Widget _buildStudentTab() {
    final d = _detail!;
    final students = (d['students'] as List? ?? []).cast<Map>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: AdminTheme.sectionTitle('Danh sách sinh viên (${students.length})')),
                  TextButton.icon(
                    onPressed: _manageStudents,
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18, color: AppColors.primary),
                    label: const Text('Quản lý SV', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có sinh viên trong học phần này.',
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

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form tạo học phần mới
// ─────────────────────────────────────────────────────────────────────────────

class _SectionFormSheet extends StatefulWidget {
  final AdminRepository repo;

  const _SectionFormSheet({required this.repo});

  @override
  State<_SectionFormSheet> createState() => _SectionFormSheetState();
}

class _SectionFormSheetState extends State<_SectionFormSheet> {
  final _courseSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _courseOptions = [];
  Map<String, dynamic>? _selectedCourse;

  final _semesterCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  bool _isLab = false;
  bool _saving = false;

  @override
  void dispose() {
    _courseSearchCtrl.dispose();
    _semesterCtrl.dispose();
    _academicYearCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
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

  String? _validateDates() {
    final ay = _academicYearCtrl.text.trim();
    final start = _startDateCtrl.text.trim();
    final end = _endDateCtrl.text.trim();

    final ayRegex = RegExp(r'^\d{4}-\d{4}$');
    if (!ayRegex.hasMatch(ay)) {
      return 'Năm học phải theo định dạng yyyy-yyyy (ví dụ: 2025-2026)';
    }
    final yearStart = int.parse(ay.substring(0, 4));
    final yearEnd = int.parse(ay.substring(5));
    if (yearEnd != yearStart + 1) {
      return 'Năm học không hợp lệ: năm sau phải bằng năm trước + 1';
    }
    if (start.isEmpty) return 'Ngày bắt đầu không được để trống';
    if (end.isEmpty) return 'Ngày kết thúc không được để trống';

    DateTime? startDate, endDate;
    try {
      startDate = DateTime.parse(start);
      endDate = DateTime.parse(end);
    } catch (_) {
      return 'Định dạng ngày không hợp lệ (yyyy-MM-dd)';
    }
    if (!endDate.isAfter(startDate)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }
    final rangeStart = DateTime(yearStart, 1, 1);
    final rangeEnd = DateTime(yearEnd, 12, 31);
    if (startDate.isBefore(rangeStart) || startDate.isAfter(rangeEnd)) {
      return 'Ngày bắt đầu phải nằm trong năm học $ay';
    }
    if (endDate.isBefore(rangeStart) || endDate.isAfter(rangeEnd)) {
      return 'Ngày kết thúc phải nằm trong năm học $ay';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_selectedCourse == null) {
      _showSnack('Vui lòng chọn môn học', isError: true);
      return;
    }
    if (_semesterCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng chọn học kỳ', isError: true);
      return;
    }
    if (_academicYearCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập năm học', isError: true);
      return;
    }
    final error = _validateDates();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repo.createAdminSection({
        'courseId': _selectedCourse!['id'],
        'isLab': _isLab,
        'semester': _semesterCtrl.text.trim(),
        'academicYear': _academicYearCtrl.text.trim(),
        'startDate': _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
        'endDate': _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
      });
      if (!mounted) return;
      await AdminNotification.show(context, 'Thêm học phần thành công');
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Thêm học phần mới',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    AdminTheme.sectionTitle('Môn học'),
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
                          itemCount: _courseOptions.length,
                          itemBuilder: (_, i) {
                            final c = _courseOptions[i];
                            return ListTile(
                              dense: true,
                              title: Text('${c['courseCode']} — ${c['courseName']}'),
                              subtitle: Text('${c['credits']} tín chỉ'),
                              onTap: () => setState(() {
                                _selectedCourse = c;
                                _courseSearchCtrl.text = '${c['courseCode']} — ${c['courseName']}';
                                _courseOptions = [];
                              }),
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
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Loại:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        _TypeToggle(value: _isLab, onChanged: (v) => setState(() => _isLab = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 28),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Thêm học phần',
                                style: TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form chỉnh sửa thông tin học phần
// ─────────────────────────────────────────────────────────────────────────────

class _SectionEditSheet extends StatefulWidget {
  final AdminRepository repo;
  final int sectionId;
  final Map<String, dynamic> detail;

  const _SectionEditSheet({
    required this.repo,
    required this.sectionId,
    required this.detail,
  });

  @override
  State<_SectionEditSheet> createState() => _SectionEditSheetState();
}

class _SectionEditSheetState extends State<_SectionEditSheet> {
  final _semesterCtrl = TextEditingController();
  final _academicYearCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _semesterCtrl.text = d['semester']?.toString() ?? '';
    _academicYearCtrl.text = d['academicYear']?.toString() ?? '';
    _startDateCtrl.text = d['startDate']?.toString() ?? '';
    _endDateCtrl.text = d['endDate']?.toString() ?? '';
  }

  @override
  void dispose() {
    _semesterCtrl.dispose();
    _academicYearCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  String? _validateAndGetError() {
    final ay = _academicYearCtrl.text.trim();
    final start = _startDateCtrl.text.trim();
    final end = _endDateCtrl.text.trim();

    // Validate format năm học yyyy-yyyy
    final ayRegex = RegExp(r'^\d{4}-\d{4}$');
    if (!ayRegex.hasMatch(ay)) {
      return 'Năm học phải theo định dạng yyyy-yyyy (ví dụ: 2025-2026)';
    }
    final yearStart = int.parse(ay.substring(0, 4));
    final yearEnd = int.parse(ay.substring(5));
    if (yearEnd != yearStart + 1) {
      return 'Năm học không hợp lệ: năm sau phải bằng năm trước + 1';
    }

    // Validate ngày không trống
    if (start.isEmpty) return 'Ngày bắt đầu không được để trống';
    if (end.isEmpty) return 'Ngày kết thúc không được để trống';

    // Parse ngày (định dạng yyyy-MM-dd từ backend)
    DateTime? startDate, endDate;
    try {
      startDate = DateTime.parse(start);
      endDate = DateTime.parse(end);
    } catch (_) {
      return 'Định dạng ngày không hợp lệ (yyyy-MM-dd)';
    }

    // Validate endDate > startDate
    if (!endDate.isAfter(startDate)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }

    // Validate nằm trong phạm vi năm học
    final rangeStart = DateTime(yearStart, 1, 1);
    final rangeEnd = DateTime(yearEnd, 12, 31);
    if (startDate.isBefore(rangeStart) || startDate.isAfter(rangeEnd)) {
      return 'Ngày bắt đầu phải nằm trong năm học $ay ($yearStart-01-01 đến $yearEnd-12-31)';
    }
    if (endDate.isBefore(rangeStart) || endDate.isAfter(rangeEnd)) {
      return 'Ngày kết thúc phải nằm trong năm học $ay ($yearStart-01-01 đến $yearEnd-12-31)';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_semesterCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng chọn học kỳ', isError: true);
      return;
    }
    if (_academicYearCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập năm học', isError: true);
      return;
    }
    final error = _validateAndGetError();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repo.updateAdminSection(widget.sectionId, {
        'semester': _semesterCtrl.text.trim(),
        'academicYear': _academicYearCtrl.text.trim(),
        'startDate': _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
        'endDate': _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
      });
      if (!mounted) return;
      await AdminNotification.show(context, 'Cập nhật học phần thành công');
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final isLab = d['isLab'] == true;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Chỉnh sửa học phần',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Hiển thị thông tin môn học (readonly)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLab ? Colors.orange.shade50 : AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isLab ? Colors.orange.shade200 : AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              isLab ? 'TH' : 'LT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isLab ? Colors.orange.shade700 : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['courseName']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  d['courseCode']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 28),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Lưu thay đổi',
                                style: TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form thêm/sửa ca học trong học phần
// ─────────────────────────────────────────────────────────────────────────────

class _SectionScheduleFormSheet extends StatefulWidget {
  final AdminRepository repo;
  final int sectionId;
  final Map<String, dynamic>? existing;

  const _SectionScheduleFormSheet({
    required this.repo,
    required this.sectionId,
    this.existing,
  });

  @override
  State<_SectionScheduleFormSheet> createState() => _SectionScheduleFormSheetState();
}

class _SectionScheduleFormSheetState extends State<_SectionScheduleFormSheet> {
  int? _dayOfWeek;
  int? _period;
  final _roomCtrl = TextEditingController();
  final _lecturerCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _dayOfWeek = (e['dayOfWeek'] as num?)?.toInt();
      _period = (e['period'] as num?)?.toInt();
      _roomCtrl.text = e['room']?.toString() ?? '';
      _lecturerCtrl.text = e['lecturer']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _roomCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_dayOfWeek == null) {
      _showSnack('Vui lòng chọn thứ', isError: true);
      return;
    }
    if (_period == null) {
      _showSnack('Vui lòng chọn ca học', isError: true);
      return;
    }
    final room = _roomCtrl.text.trim();
    final lecturer = _lecturerCtrl.text.trim();
    if (room.isEmpty) {
      _showSnack('Phòng học không được để trống', isError: true);
      return;
    }
    if (!RegExp(r'^[\p{L}\d\s.\-]+$', unicode: true).hasMatch(room)) {
      _showSnack('Tên phòng không được chứa ký tự đặc biệt', isError: true);
      return;
    }
    if (lecturer.isEmpty) {
      _showSnack('Giảng viên không được để trống', isError: true);
      return;
    }
    if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(lecturer)) {
      _showSnack('Tên giảng viên không được chứa số hoặc ký tự đặc biệt', isError: true);
      return;
    }
    setState(() => _saving = true);
    final payload = {
      'dayOfWeek': _dayOfWeek,
      'period': _period,
      'room': room,
      'lecturer': lecturer,
    };
    try {
      if (widget.existing != null) {
        final scheduleId = (widget.existing!['scheduleId'] as num).toInt();
        await widget.repo.updateScheduleInSection(scheduleId, payload);
        if (!mounted) return;
        await AdminNotification.show(context, 'Cập nhật ca học thành công');
      } else {
        await widget.repo.addScheduleToSection(widget.sectionId, payload);
        if (!mounted) return;
        await AdminNotification.show(context, 'Thêm ca học thành công');
      }
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(isEdit ? 'Sửa ca học' : 'Thêm ca học',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
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
                                    child: Text(e.value, overflow: TextOverflow.ellipsis)))
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
                    const SizedBox(height: 24),
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? 'Lưu thay đổi' : 'Thêm ca học',
                                style: const TextStyle(fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Picker (chọn thủ công)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionStudentPickerScreen extends StatefulWidget {
  final AdminRepository repo;
  final int sectionId;
  final List<int> currentStudentIds;

  const _SectionStudentPickerScreen({
    required this.repo,
    required this.sectionId,
    required this.currentStudentIds,
  });

  @override
  State<_SectionStudentPickerScreen> createState() => _SectionStudentPickerScreenState();
}

class _SectionStudentPickerScreenState extends State<_SectionStudentPickerScreen> {
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
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách sinh viên', isError: true);
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
      await widget.repo.updateSectionStudents(widget.sectionId, _selectedIds.toList());
      if (!mounted) return;
      await AdminNotification.show(context, 'Đã cập nhật danh sách sinh viên');
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Cập nhật thất bại', isError: true);
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
        'Chọn sinh viên',
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Xác nhận',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: AdminTheme.inputDecoration('Tìm theo tên hoặc MSSV...',
                  prefixIcon: const Icon(Icons.search, size: 20)),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text('Đã chọn ${_selectedIds.length} / ${_allStudents.length} sinh viên',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    if (_selectedIds.length == _allStudents.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_allStudents.map((s) => (s['id'] as num).toInt()));
                    }
                  }),
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
                          final selected = _selectedIds.contains(id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (s['fullName']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(s['fullName']?.toString() ?? '',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: selected ? AppColors.primary : AppColors.textPrimary)),
                            subtitle: Text(s['studentCode']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12)),
                            trailing: Checkbox(
                              value: selected,
                              activeColor: AppColors.primary,
                              onChanged: (_) => setState(() {
                                if (selected) {
                                  _selectedIds.remove(id);
                                } else {
                                  _selectedIds.add(id);
                                }
                              }),
                            ),
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            }),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AdminNotification.showError(context, msg);
    } else {
      AdminNotification.show(context, msg);
    }
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  final bool isLab;
  const _TypeBadge({required this.isLab});

  @override
  Widget build(BuildContext context) => Container(
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

class _TypeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _ToggleChip(label: 'Lý thuyết', selected: !value, onTap: () => onChanged(false)),
          const SizedBox(width: 8),
          _ToggleChip(
              label: 'Thực hành',
              selected: value,
              onTap: () => onChanged(true),
              selectedColor: Colors.orange.shade600),
        ],
      );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap, this.selectedColor});

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
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
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      widget.controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        readOnly: true,
        onTap: _pick,
        decoration: AdminTheme.inputDecoration(widget.label,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
      );
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String Function(String)? itemLabel;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        decoration: AdminTheme.inputDecoration(label),
        isExpanded: true,
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Tất cả $label')),
          ...items.map((v) => DropdownMenuItem<String>(
              value: v, child: Text(itemLabel != null ? itemLabel!(v) : v))),
        ],
        onChanged: onChanged,
      );
}
