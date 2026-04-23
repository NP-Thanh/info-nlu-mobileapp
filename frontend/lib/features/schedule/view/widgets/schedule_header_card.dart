import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../model/schedule_model.dart';

class ScheduleHeaderCard extends StatelessWidget {
  final ScheduleData scheduleData;
  final int currentWeek;
  final DateTime weekStart;
  final DateTime weekEnd;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onCalendar;

  const ScheduleHeaderCard({
    super.key,
    required this.scheduleData,
    required this.currentWeek,
    required this.weekStart,
    required this.weekEnd,
    this.onPrev,
    this.onNext,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final semLabel = 'HỌC KỲ ${scheduleData.semester} (${scheduleData.academicYear})';
    final weekLabel = 'Tuần $currentWeek';
    final dateRange = '${_fmt(weekStart)} - ${_fmt(weekEnd)}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          // Semester row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                semLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onCalendar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Week navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                onTap: onPrev,
              ),
              Column(
                children: [
                  Text(
                    weekLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRange,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _NavButton(
                icon: Icons.chevron_right,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : Colors.white38,
          size: 22,
        ),
      ),
    );
  }
}
