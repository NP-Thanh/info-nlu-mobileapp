class ScheduleItem {
  final int scheduleId;
  final String courseName;
  final String courseCode;
  final int credits;
  final String lecturer;
  final String room;
  final int dayOfWeek;
  final int period;   // 1-4
  final String periodStart;
  final String periodEnd;

  const ScheduleItem({
    required this.scheduleId,
    required this.courseName,
    required this.courseCode,
    required this.credits,
    required this.lecturer,
    required this.room,
    required this.dayOfWeek,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      scheduleId: json['scheduleId'] ?? 0,
      courseName: json['courseName'] ?? '',
      courseCode: json['courseCode'] ?? '',
      credits: json['credits'] ?? 0,
      lecturer: json['lecturer'] ?? '',
      room: json['room'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 2,
      period: json['period'] ?? 1,
      periodStart: json['periodStart'] ?? '07:00',
      periodEnd: json['periodEnd'] ?? '09:15',
    );
  }

  String get periodLabel => 'Ca $period';
  String get timeRange => '$periodStart - $periodEnd';
}

class ScheduleData {
  final String semester;
  final String academicYear;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ScheduleItem> items;

  const ScheduleData({
    required this.semester,
    required this.academicYear,
    this.startDate,
    this.endDate,
    required this.items,
  });

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      semester: json['semester'] ?? '',
      academicYear: json['academicYear'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => items.isEmpty;

  /// Tổng số tuần của học kỳ
  int get totalWeeks {
    if (startDate == null || endDate == null) return 0;
    return (endDate!.difference(_mondayOf(startDate!)).inDays / 7).ceil();
  }

  /// Ngày thứ Hai của tuần thứ [week] (1-based)
  DateTime weekStart(int week) {
    if (startDate == null) return DateTime.now();
    return _mondayOf(startDate!).add(Duration(days: (week - 1) * 7));
  }

  DateTime weekEnd(int week) => weekStart(week).add(const Duration(days: 6));

  // Tuần hiện tại
  int currentWeek(DateTime now) {
    if (startDate == null) return 1;
    final semStart = _mondayOf(startDate!);
    if (now.isBefore(semStart)) return 1;
    final week = (now.difference(semStart).inDays / 7).floor() + 1;
    return week.clamp(1, totalWeeks == 0 ? 99 : totalWeeks);
  }

  // Tuần chứa ngày
  int weekOfDate(DateTime date) {
    if (startDate == null) return 1;
    final semStart = _mondayOf(startDate!);
    if (date.isBefore(semStart)) return 1;
    final week = (date.difference(semStart).inDays / 7).floor() + 1;
    return week.clamp(1, totalWeeks == 0 ? 99 : totalWeeks);
  }

  // Các môn học trong tuần
  List<ScheduleItem> itemsForWeek(int week) {
    if (startDate == null || endDate == null) return [];
    final wStart = weekStart(week);
    final wEnd = weekEnd(week);

    if (wEnd.isBefore(startDate!) || wStart.isAfter(endDate!)) return [];
    return items.toList();
  }

  // Tất cả ngày có lịch học trong học kỳ
  Set<DateTime> get allScheduledDates {
    final dates = <DateTime>{};
    if (startDate == null || endDate == null || items.isEmpty) return dates;
    final semStart = _mondayOf(startDate!);
    for (int week = 1; week <= totalWeeks; week++) {
      final wStart = semStart.add(Duration(days: (week - 1) * 7));
      final wEnd = wStart.add(const Duration(days: 6));
      if (wStart.isAfter(endDate!)) break;
      for (final item in items) {
        final d = _dateOfDayInWeek(wStart, item.dayOfWeek);
        if (!d.isBefore(startDate!) && !d.isAfter(endDate!)) {
          dates.add(DateTime(d.year, d.month, d.day));
        }
      }
    }
    return dates;
  }

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  static DateTime _dateOfDayInWeek(DateTime monday, int dayOfWeek) {
    final offset = dayOfWeek == 8 ? 6 : dayOfWeek - 2;
    return monday.add(Duration(days: offset));
  }
}
