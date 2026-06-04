import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/admin_widgets.dart';

class AdminChatbotDetailScreen extends StatelessWidget {
  final Map<String, dynamic> log;

  const AdminChatbotDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isFlagged = log['isFlagged'] == true;
    final studentCode = log['studentCode']?.toString() ?? '—';
    final studentName = log['studentName']?.toString() ?? '—';
    final createdAt = _formatDate(log['createdAt']?.toString());
    final question = log['question']?.toString() ?? '';
    final answer = log['answer']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AdminTheme.appBar(context, 'Chi tiết log chat'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          _InfoCard(children: [
            _InfoRow(label: 'MSSV', value: studentCode),
            _InfoRow(label: 'Sinh viên', value: studentName),
            _InfoRow(label: 'Thời gian', value: createdAt),
            _InfoRow(
              label: 'Trạng thái',
              value: isFlagged ? 'Vi phạm' : 'Bình thường',
              valueColor: isFlagged ? Colors.red.shade600 : Colors.green.shade600,
            ),
          ]),
          const SizedBox(height: 16),
          // Question
          _BubbleCard(
            label: 'Câu hỏi sinh viên',
            content: question,
            labelColor: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.06),
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          // Answer
          _BubbleCard(
            label: 'Trả lời chatbot',
            content: answer,
            labelColor: Colors.blue.shade700,
            bgColor: Colors.blue.shade50,
            icon: Icons.smart_toy_outlined,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _BubbleCard extends StatelessWidget {
  final String label;
  final String content;
  final Color labelColor;
  final Color bgColor;
  final IconData icon;
  const _BubbleCard({
    required this.label,
    required this.content,
    required this.labelColor,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: labelColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: labelColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: labelColor)),
          ]),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}
