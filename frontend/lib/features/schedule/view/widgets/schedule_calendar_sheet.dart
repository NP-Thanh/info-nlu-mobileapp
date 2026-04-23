import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../model/schedule_model.dart';

class ScheduleCalendarSheet extends StatefulWidget {
  final ScheduleData scheduleData;
  final int currentWeek;
  final ValueChanged<DateTime> onDaySelected;

  const ScheduleCalendarSheet({
    super.key,
    required this.scheduleData,
    required this.currentWeek,
    required this.onDaySelected,
  });

  @override
  State<ScheduleCalendarSheet> createState() => _ScheduleCalendarSheetState();
}

class _ScheduleCalendarSheetState extends State<ScheduleCalendarSheet> {
  late DateTime _displayMonth;
  late Set<DateTime> _scheduledDates;

  @override
  void initState() {
    super.initState();
    final wStart = widget.scheduleData.weekStart(widget.currentWeek);
    _displayMonth = DateTime(wStart.year, wStart.month);
    _scheduledDates = widget.scheduleData.allScheduledDates;
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Tháng ${_displayMonth.month} năm ${_displayMonth.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              // Day of week labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              // Calendar grid
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildCalendarGrid(),
                  ),
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Có lịch học',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    // weekday: 1=Mon, 7=Sun
    int startOffset = firstDay.weekday - 1; // 0=Mon

    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayMonth.year, _displayMonth.month, day);
      final dateKey = DateTime(date.year, date.month, date.day);
      final hasSchedule = _scheduledDates.contains(dateKey);
      final isToday = _isSameDay(date, DateTime.now());

      cells.add(_DayCell(
        day: day,
        hasSchedule: hasSchedule,
        isToday: isToday,
        onTap: () => widget.onDaySelected(date),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasSchedule;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.hasSchedule,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (hasSchedule)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
