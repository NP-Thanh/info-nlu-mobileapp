import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';
import 'admin_chatbot_detail_screen.dart';

class AdminChatbotScreen extends StatefulWidget {
  const AdminChatbotScreen({super.key});

  @override
  State<AdminChatbotScreen> createState() => _AdminChatbotScreenState();
}

class _AdminChatbotScreenState extends State<AdminChatbotScreen> {
  final _repo = AdminRepository();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  // filter: null = tất cả, true = vi phạm, false = bình thường
  bool? _filterFlagged;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _fetchLogs();

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.getChatbotLogs(
        keyword: _searchCtrl.text,
        flagged: _filterFlagged,
      );
      if (!mounted) return;
      setState(() => _logs = list);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách log', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Selection ──────────────────────────────────────────────────────────────

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
      if (_selectedIds.length == _logs.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(_logs.map((l) => (l['id'] as num).toInt()));
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

  // ── Flag / Unflag ──────────────────────────────────────────────────────────

  Future<void> _flagSelected(bool flagged) async {
    if (_selectedIds.isEmpty) return;
    final action = flagged ? 'gắn cờ vi phạm' : 'bỏ gắn cờ';
    final confirm = await _showConfirmDialog(
      title: flagged ? 'Gắn cờ vi phạm' : 'Bỏ gắn cờ',
      content: 'Bạn muốn $action ${_selectedIds.length} log chat đã chọn?',
      confirmLabel: flagged ? 'Gắn cờ' : 'Bỏ cờ',
      confirmColor: flagged ? Colors.red.shade600 : AppColors.primary,
    );
    if (confirm != true) return;
    try {
      await _repo.flagChatbotLogs(_selectedIds.toList(), flagged: flagged);
      _showSnack(flagged
          ? 'Đã gắn cờ ${_selectedIds.length} log'
          : 'Đã bỏ cờ ${_selectedIds.length} log');
      _cancelSelection();
      _fetchLogs();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Thao tác thất bại', isError: true);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await _showConfirmDialog(
      title: 'Xóa log chat',
      content: 'Xóa vĩnh viễn ${_selectedIds.length} log chat đã chọn?',
      confirmLabel: 'Xóa',
      confirmColor: Colors.red.shade600,
    );
    if (confirm != true) return;
    try {
      await _repo.deleteChatbotLogs(_selectedIds.toList());
      _showSnack('Đã xóa ${_selectedIds.length} log chat');
      _cancelSelection();
      _fetchLogs();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa thất bại', isError: true);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openDetail(Map<String, dynamic> log) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminChatbotDetailScreen(log: log)),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
    ));
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── AppBars ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _normalAppBar() {
    return AdminTheme.appBar(context, 'Quản lý chatbot');
  }

  PreferredSizeWidget _selectionAppBar() {
    final allSelected = _selectedIds.length == _logs.length && _logs.isNotEmpty;
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _cancelSelection,
      ),
      title: Text('Đã chọn ${_selectedIds.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      actions: [
        TextButton(
          onPressed: _toggleSelectAll,
          child: Text(allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white24)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _selectionMode ? _selectionAppBar() : _normalAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildStatsBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _selectionMode ? _buildSelectionBar() : null,
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(children: [
        // Search field — realtime
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Tìm theo MSSV hoặc tên sinh viên...',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _fetchLogs();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        // Filter chips
        Row(children: [
          _FilterChip(
            label: 'Tất cả',
            selected: _filterFlagged == null,
            onTap: () => setState(() {
              _filterFlagged = null;
              _fetchLogs();
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Vi phạm',
            selected: _filterFlagged == true,
            selectedColor: Colors.red.shade600,
            icon: Icons.flag,
            onTap: () => setState(() {
              _filterFlagged = _filterFlagged == true ? null : true;
              _fetchLogs();
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bình thường',
            selected: _filterFlagged == false,
            selectedColor: Colors.green.shade600,
            icon: Icons.check_circle_outline,
            onTap: () => setState(() {
              _filterFlagged = _filterFlagged == false ? null : false;
              _fetchLogs();
            }),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        Text('${_logs.length} log chat',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        if (_filterFlagged != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (_filterFlagged == true ? Colors.red : Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _filterFlagged == true ? 'Vi phạm' : 'Bình thường',
              style: TextStyle(
                  fontSize: 11,
                  color: _filterFlagged == true ? Colors.red.shade700 : Colors.green.shade700),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_logs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.smart_toy_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('Không có log chat nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchLogs,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: _logs.length,
        separatorBuilder: (_, _i) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _LogCard(
          log: _logs[i],
          selected: _selectedIds.contains((_logs[i]['id'] as num).toInt()),
          selectionMode: _selectionMode,
          onTap: () {
            final id = (_logs[i]['id'] as num).toInt();
            if (_selectionMode) {
              _toggleSelect(id);
            } else {
              _openDetail(_logs[i]);
            }
          },
          onLongPress: () {
            final id = (_logs[i]['id'] as num).toInt();
            if (!_selectionMode) {
              _enterSelectionMode(id);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedIds.isEmpty ? null : () => _flagSelected(false),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Bỏ cờ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _selectedIds.isEmpty ? null : () => _flagSelected(true),
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('Gắn cờ vi phạm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Icon(Icons.delete_outline, size: 20),
        ),
      ]),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _LogCard({
    required this.log,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isFlagged = log['isFlagged'] == true;
    final studentCode = log['studentCode']?.toString() ?? '—';
    final studentName = log['studentName']?.toString() ?? '—';
    final question = log['question']?.toString() ?? '';
    final answer = log['answer']?.toString() ?? '';
    final createdAt = _formatDate(log['createdAt']?.toString());

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : isFlagged
                      ? Colors.red.shade200
                      : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox or flag icon
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      size: 22,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFlagged
                            ? Colors.red.shade50
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFlagged ? Colors.red.shade200 : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        isFlagged ? Icons.flag : Icons.chat_outlined,
                        size: 18,
                        color: isFlagged ? Colors.red.shade600 : AppColors.primary,
                      ),
                    ),
                  ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student + date row
                      Row(children: [
                        Expanded(
                          child: Text(
                            '$studentCode • $studentName',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(createdAt,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 6),
                      // Question preview
                      Text(
                        question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      // Answer preview
                      Text(
                        answer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                      ),
                      // Flag badge
                      if (isFlagged) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.flag, size: 11, color: Colors.red.shade600),
                            const SizedBox(width: 4),
                            Text('Vi phạm',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.red.shade600)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!selectionMode)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? selectedColor;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? color : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
