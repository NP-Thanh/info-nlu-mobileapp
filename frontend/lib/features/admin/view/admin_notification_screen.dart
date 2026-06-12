import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _repo = AdminRepository();
  final _contentController = TextEditingController();

  List<Map<String, dynamic>> _notifications = [];
  List<String> _typeOptions = [];
  String? _filterType;
  bool _loading = true;

  bool _selectionMode = false;
  final Set<_GroupKey> _selectedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _fetchNotifications();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    // debounce thủ công đơn giản
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fetchNotifications();
    });
  }

  Future<void> _loadFilterOptions() async {
    try {
      final opts = await _repo.getNotificationFilterOptions();
      if (!mounted) return;
      setState(() {
        _typeOptions = List<String>.from(opts['types'] as List? ?? []);
      });
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _repo.getAdminNotifications(
        content: _contentController.text,
        type: _filterType,
      );
      if (!mounted) return;
      setState(() => _notifications = list);
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] ?? 'Không tải được danh sách');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _enterSelection(_GroupKey key) {
    setState(() {
      _selectionMode = true;
      _selectedGroups.add(key);
    });
  }

  void _toggleSelect(_GroupKey key) {
    setState(() {
      if (_selectedGroups.contains(key)) {
        _selectedGroups.remove(key);
        if (_selectedGroups.isEmpty) _selectionMode = false;
      } else {
        _selectedGroups.add(key);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectionMode = true;
      _selectedGroups.clear();
      for (final n in _notifications) {
        _selectedGroups.add(_GroupKey.fromMap(n));
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedGroups.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedGroups.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa thông báo'),
        content: Text('Xóa ${_selectedGroups.length} nhóm thông báo đã chọn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: AdminTheme.primaryButtonStyle().copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.red.shade700),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final groups = _selectedGroups
          .map((k) => {'title': k.title, 'content': k.content, 'type': k.type})
          .toList();
      await _repo.deleteAdminNotificationGroups(groups);
      if (!mounted) return;
      AdminNotification.show(context, 'Đã xóa thông báo');
      _exitSelection();
      _fetchNotifications();
    } on DioException catch (e) {
      _showError(e.response?.data?['message'] ?? 'Xóa thất bại');
    }
  }

  void _openDetail(Map<String, dynamic> n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationDetailScreen(
          title: n['title'] as String? ?? '',
          content: n['content'] as String? ?? '',
          type: n['type'] as String?,
          repo: _repo,
        ),
      ),
    );
  }

  Future<void> _openSendForm() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _SendNotificationScreen(repo: _repo)),
    );
    if (sent == true) {
      _loadFilterOptions();
      _fetchNotifications();
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    AdminNotification.showError(context, msg);
  }

  void _resetFilters() {
    _contentController.clear();
    setState(() {
      _filterType = null;
    });
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(
        context,
        _selectionMode ? 'Đã chọn ${_selectedGroups.length}' : 'Quản lý thông báo',
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Tất cả', style: TextStyle(color: AppColors.primary)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: _exitSelection),
              ]
            : null,
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _openSendForm,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Gửi thông báo', style: TextStyle(color: Colors.white)),
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
                  label: Text(
                    'Xóa ${_selectedGroups.length} thông báo',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? const Center(
                        child: Text('Không có thông báo', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _NotificationCard(
                            data: _notifications[i],
                            selected: _selectedGroups.contains(_GroupKey.fromMap(_notifications[i])),
                            selectionMode: _selectionMode,
                            onTap: () => _selectionMode
                                ? _toggleSelect(_GroupKey.fromMap(_notifications[i]))
                                : _openDetail(_notifications[i]),
                            onLongPress: () => _selectionMode
                                ? _toggleSelect(_GroupKey.fromMap(_notifications[i]))
                                : _enterSelection(_GroupKey.fromMap(_notifications[i])),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          AdminTheme.searchField(
            controller: _contentController,
            hint: 'Tìm kiếm nội dung...',
            onChanged: (_) {},
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DropdownFilter(
                  hint: 'Loại',
                  value: _filterType,
                  items: _typeOptions,
                  onChanged: (v) {
                    setState(() => _filterType = v);
                    _fetchNotifications();
                  },
                ),
              ),
              if (_contentController.text.isNotEmpty || _filterType != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _resetFilters,
                  tooltip: 'Xóa bộ lọc',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationCard({
    required this.data,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final type = data['type'] as String?;
    final count = (data['recipientCount'] as num?)?.toInt() ?? 0;
    final createdAt = _parseDate(data['createdAt']);

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
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
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
                        if (type != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor(type).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 11,
                                color: _typeColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      content,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$count sinh viên',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
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

  Color _typeColor(String type) {
    return switch (type.toLowerCase()) {
      'schedule' => Colors.blue.shade700,
      'grade' => Colors.green.shade700,
      'general' => Colors.orange.shade700,
      _ => AppColors.primary,
    };
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    if (v is List && v.length >= 3) {
      return DateTime(
        (v[0] as num).toInt(),
        (v[1] as num).toInt(),
        (v[2] as num).toInt(),
        v.length > 3 ? (v[3] as num).toInt() : 0,
        v.length > 4 ? (v[4] as num).toInt() : 0,
      );
    }
    return null;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Dropdown filter ────────────────────────────────────────────────────────

class _DropdownFilter extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tất cả $hint', style: const TextStyle(fontSize: 13)),
            ),
            ...items.map(
              (e) => DropdownMenuItem<String>(value: e, child: Text(e, style: const TextStyle(fontSize: 13))),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Group key ────────────────────────────────────────────────────────────────

class _GroupKey {
  final String title;
  final String content;
  final String? type;

  const _GroupKey({required this.title, required this.content, this.type});

  factory _GroupKey.fromMap(Map<String, dynamic> m) => _GroupKey(
        title: m['title'] as String? ?? '',
        content: m['content'] as String? ?? '',
        type: m['type'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is _GroupKey && other.title == title && other.content == content && other.type == type;

  @override
  int get hashCode => Object.hash(title, content, type);
}

// ── Detail Screen ────────────────────────────────────────────────────────────

class _NotificationDetailScreen extends StatefulWidget {
  final String title;
  final String content;
  final String? type;
  final AdminRepository repo;

  const _NotificationDetailScreen({
    required this.title,
    required this.content,
    this.type,
    required this.repo,
  });

  @override
  State<_NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<_NotificationDetailScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allRecipients = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final kw = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = kw.isEmpty
          ? List.from(_allRecipients)
          : _allRecipients.where((r) {
              final code = (r['studentCode'] as String? ?? '').toLowerCase();
              final name = (r['fullName'] as String? ?? '').toLowerCase();
              return code.contains(kw) || name.contains(kw);
            }).toList();
    });
  }

  Future<void> _fetch() async {
    try {
      final detail = await widget.repo.getAdminNotificationDetail(
        title: widget.title,
        content: widget.content,
        type: widget.type,
      );
      final recipients = List<Map<String, dynamic>>.from(
        (detail['recipients'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _allRecipients = recipients;
        _filtered = List.from(recipients);
      });
    } catch (e) {
      if (mounted) AdminNotification.showError(context, 'Lỗi tải chi tiết');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(context, 'Chi tiết thông báo'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.type != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.type!,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.content,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_allRecipients.length} sinh viên đã nhận',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AdminTheme.searchField(
                    controller: _searchController,
                    hint: 'Tìm kiếm MSSV hoặc tên...',
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: 8),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text('Không tìm thấy sinh viên', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = _filtered[i];
                            final isRead = r['read'] as bool? ?? false;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surface,
                                child: Text(
                                  (r['fullName'] as String? ?? '?').isNotEmpty
                                      ? (r['fullName'] as String)[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                r['fullName'] as String? ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                r['studentCode'] as String? ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              trailing: Icon(
                                isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                                size: 18,
                                color: isRead ? Colors.green : AppColors.textSecondary,
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

// ── Send Screen ──────────────────────────────────────────────────────────────

class _SendNotificationScreen extends StatefulWidget {
  final AdminRepository repo;
  const _SendNotificationScreen({required this.repo});

  @override
  State<_SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<_SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedType;
  final _studentSearchController = TextEditingController();

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final Set<int> _selectedStudentIds = {};
  bool _loadingStudents = true;
  bool _sending = false;
  bool _step2 = false; // false = form, true = chọn sv

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _studentSearchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final list = await widget.repo.getAllStudentsForSchedule();
      if (!mounted) return;
      setState(() {
        _allStudents = list;
        _filteredStudents = List.from(list);
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  void _filterStudents() {
    final kw = _studentSearchController.text.trim().toLowerCase();
    setState(() {
      _filteredStudents = kw.isEmpty
          ? List.from(_allStudents)
          : _allStudents.where((s) {
              final code = (s['studentCode'] as String? ?? '').toLowerCase();
              final name = (s['fullName'] as String? ?? '').toLowerCase();
              return code.contains(kw) || name.contains(kw);
            }).toList();
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedStudentIds.length == _filteredStudents.length) {
        _selectedStudentIds.removeAll(_filteredStudents.map((s) => (s['id'] as num).toInt()));
      } else {
        _selectedStudentIds.addAll(_filteredStudents.map((s) => (s['id'] as num).toInt()));
      }
    });
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      AdminNotification.showError(context, 'Vui lòng nhập tiêu đề');
      return;
    }
    if (content.isEmpty) {
      AdminNotification.showError(context, 'Vui lòng nhập nội dung');
      return;
    }
    if (_selectedType == null || _selectedType!.isEmpty) {
      AdminNotification.showError(context, 'Vui lòng chọn loại thông báo');
      return;
    }
    if (_selectedStudentIds.isEmpty) {
      AdminNotification.showError(context, 'Vui lòng chọn ít nhất 1 sinh viên');
      return;
    }

    setState(() => _sending = true);
    try {
      final msg = await widget.repo.sendAdminNotification(
        title: title,
        content: content,
        type: _selectedType,
        studentIds: _selectedStudentIds.toList(),
      );
      if (!mounted) return;
      await AdminNotification.show(context, msg);
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      if (mounted) AdminNotification.showError(context, e.response?.data?['message'] ?? 'Gửi thất bại');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(context, 'Gửi thông báo mới'),
      body: _step2 ? _buildStudentPicker() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Tiêu đề *'),
          _textField(_titleController, 'Nhập tiêu đề thông báo'),
          const SizedBox(height: 16),
          _label('Nội dung *'),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: _inputDecoration('Nhập nội dung thông báo...'),
          ),
          const SizedBox(height: 16),
          _label('Loại thông báo *'),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: _inputDecoration('Chọn loại thông báo'),
            items: const [
              DropdownMenuItem(value: 'SYSTEM', child: Text('Schedule — Lịch học')),
              DropdownMenuItem(value: 'grade', child: Text('Grade — Điểm số')),
              DropdownMenuItem(value: 'general', child: Text('General — Thông báo chung')),
            ],
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 24),
          // Chọn sinh viên button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.people_outline, color: AppColors.primary),
            label: Text(
              _selectedStudentIds.isEmpty
                  ? 'Chọn sinh viên để gửi'
                  : 'Đã chọn ${_selectedStudentIds.length} sinh viên',
              style: const TextStyle(color: AppColors.primary),
            ),
            onPressed: () => setState(() => _step2 = true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: AdminTheme.primaryButtonStyle(),
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Gửi thông báo', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPicker() {
    final allSelected = _filteredStudents.isNotEmpty &&
        _filteredStudents.every((s) => _selectedStudentIds.contains((s['id'] as num).toInt()));

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              AdminTheme.searchField(
                controller: _studentSearchController,
                hint: 'Tìm kiếm MSSV hoặc tên...',
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chọn: ${_selectedStudentIds.length}/${_allStudents.length}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: _selectAll,
                    icon: Icon(
                      allSelected ? Icons.deselect : Icons.select_all,
                      size: 18, color: AppColors.primary,
                    ),
                    label: Text(
                      allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _filteredStudents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = _filteredStudents[i];
                    final id = (s['id'] as num).toInt();
                    final checked = _selectedStudentIds.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) => setState(() {
                        if (checked) {
                          _selectedStudentIds.remove(id);
                        } else {
                          _selectedStudentIds.add(id);
                        }
                      }),
                      title: Text(
                        s['fullName'] as String? ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        s['studentCode'] as String? ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: AdminTheme.primaryButtonStyle(),
              onPressed: () => setState(() => _step2 = false),
              child: Text(
                'Xác nhận (${_selectedStudentIds.length} sinh viên)',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _textField(TextEditingController c, String hint) => TextField(
        controller: c,
        decoration: _inputDecoration(hint),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
