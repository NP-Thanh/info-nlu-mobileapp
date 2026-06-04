import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Thông báo dạng dialog — rõ ràng hơn SnackBar, bấm Xác nhận để tắt.
  class AdminNotification {
  /// Thông báo thành công (xanh lá)
  static Future<void> show(
    BuildContext context,
    String message, {
    String? title,
  }) =>
      _show(context, message, title: title ?? 'Thông báo', color: Colors.green.shade600, icon: Icons.check_circle_outline);

  /// Thông báo lỗi (đỏ)
  static Future<void> showError(
    BuildContext context,
    String message, {
    String? title,
  }) =>
      _show(context, message, title: title ?? 'Lỗi', color: Colors.red.shade600, icon: Icons.error_outline);

  /// Thông báo cảnh báo (cam)
  static Future<void> showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) =>
      _show(context, message, title: title ?? 'Cảnh báo', color: Colors.orange.shade600, icon: Icons.warning_amber_outlined);

  /// Thông báo thông tin (xanh dương)
  static Future<void> showInfo(
    BuildContext context,
    String message, {
    String? title,
  }) =>
      _show(context, message, title: title ?? 'Thông tin', color: AppColors.primary, icon: Icons.info_outline);

  static Future<void> _show(
    BuildContext context,
    String message, {
    required String title,
    required Color color,
    required IconData icon,
  }) {
    if (!context.mounted) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Xác nhận', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTheme {
  static AppBar appBar(BuildContext context, String title, {List<Widget>? actions}) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      actions: actions,
    );
  }

  static InputDecoration inputDecoration(String label, {String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  static ButtonStyle outlinedButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  static Widget sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      );

  static Widget infoCard({required Widget child}) => Container(
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

/// Gợi ý hiển thị overlay — không chiếm thêm chiều cao layout (tránh overflow).
class AdminSuggestionField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final Future<List<String>> Function(String keyword) onSearch;
  final VoidCallback? onSelected;
  final bool enabled;

  const AdminSuggestionField({
    super.key,
    required this.label,
    required this.controller,
    required this.onSearch,
    this.onSelected,
    this.enabled = true,
  });

  @override
  State<AdminSuggestionField> createState() => _AdminSuggestionFieldState();
}

class _AdminSuggestionFieldState extends State<AdminSuggestionField> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _load(String value) async {
    if (!widget.enabled) return;
    try {
      final data = await widget.onSearch(value);
      if (!mounted) return;
      setState(() => _suggestions = data);
      if (data.isEmpty) {
        _removeOverlay();
      } else {
        _showOverlay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _suggestions = []);
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? MediaQuery.sizeOf(context).width - 32;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final text = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: AdminHighlightedText(text: text, query: widget.controller.text),
                      onTap: () {
                        widget.controller.text = text;
                        setState(() => _suggestions = []);
                        _removeOverlay();
                        widget.onSelected?.call();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        key: _fieldKey,
        controller: widget.controller,
        enabled: widget.enabled,
        decoration: AdminTheme.inputDecoration(widget.label),
        onChanged: _load,
        onTap: () {
          if (_suggestions.isNotEmpty) _showOverlay();
        },
      ),
    );
  }
}

class AdminSuggestionCardFromMaps extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String query;
  final String Function(Map<String, dynamic>) displayBuilder;
  final void Function(Map<String, dynamic>) onSelect;

  const AdminSuggestionCardFromMaps({
    super.key,
    required this.items,
    required this.query,
    required this.displayBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final text = displayBuilder(item);
          return ListTile(
            dense: true,
            title: AdminHighlightedText(text: text, query: query),
            onTap: () => onSelect(item),
          );
        },
      ),
    );
  }
}

class AdminHighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const AdminHighlightedText({super.key, required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start < 0) return Text(text);
    final end = start + lowerQuery.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
