import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../model/schedule_model.dart';

// Màu ca học
const _periodColors = [
  Color(0xFF1565C0), // Ca 1 — xanh dương
  Color(0xFF2E7D32), // Ca 2 — xanh lá
  Color(0xFFE65100), // Ca 3 — cam
  Color(0xFF6A1B9A), // Ca 4 — tím
];

Color _colorForPeriod(int period) =>
    _periodColors[(period - 1).clamp(0, _periodColors.length - 1)];

class ScheduleDaySection extends StatelessWidget {
  final int dayOfWeek;
  final DateTime date;
  final List<ScheduleItem> items;

  const ScheduleDaySection({
    super.key,
    required this.dayOfWeek,
    required this.date,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Date circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Th${date.month}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? Colors.white70 : AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Day label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dayLabel(dayOfWeek),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Hôm nay',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Count badge
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length} môn',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Cards or empty
          if (items.isEmpty)
            _EmptyDay(isToday: isToday)
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ScheduleCard(item: item),
                )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _dayLabel(int dow) {
    const labels = {
      2: 'Thứ Hai', 3: 'Thứ Ba', 4: 'Thứ Tư',
      5: 'Thứ Năm', 6: 'Thứ Sáu', 7: 'Thứ Bảy', 8: 'Chủ Nhật'
    };
    return labels[dow] ?? 'Thứ $dow';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  const _EmptyDay({this.isToday = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.free_breakfast_outlined, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Text(
            isToday ? 'Không có lịch học hôm nay' : 'Không có lịch học',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _colorForPeriod(item.period);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Time column
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                border: Border(right: BorderSide(color: color.withOpacity(0.1))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ca ${item.period}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.periodStart,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Icon(Icons.arrow_downward_rounded, size: 10, color: color.withOpacity(0.5)),
                  ),
                  Text(
                    item.periodEnd,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course name
                    Text(
                      item.courseName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Lecturer
                    _InfoChip(
                      icon: Icons.person_outline_rounded,
                      label: item.lecturer,
                    ),
                    const SizedBox(height: 4),
                    // Room
                    _InfoChip(
                      icon: Icons.meeting_room_outlined,
                      label: item.room,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.8)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color == AppColors.textSecondary
                  ? AppColors.textSecondary
                  : color,
              fontWeight: color == AppColors.textSecondary
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
