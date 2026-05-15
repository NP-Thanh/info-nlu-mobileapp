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
  final DateTime? enrollmentStartDate;
  final DateTime? enrollmentEndDate;

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
    this.enrollmentStartDate,
    this.enrollmentEndDate,
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
      enrollmentStartDate: json['enrollmentStartDate'] != null
          ? DateTime.parse(json['enrollmentStartDate'])
          : null,
      enrollmentEndDate: json['enrollmentEndDate'] != null
          ? DateTime.parse(json['enrollmentEndDate'])
          : null,
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

    // Tuần này phải nằm trong khoảng học kỳ
    if (wEnd.isBefore(startDate!) || wStart.isAfter(endDate!)) return [];

    // Lọc từng item theo enrollmentEndDate riêng của nó
    return items.where((item) {
      // Ngày cụ thể của môn này trong tuần đang xem
      final itemDate = _dateOfDayInWeek(wStart, item.dayOfWeek);

      // Nếu item có enrollmentEndDate riêng, dùng nó để lọc
      final itemEnd = item.enrollmentEndDate ?? endDate!;
      final itemStart = item.enrollmentStartDate ?? startDate!;

      return !itemDate.isBefore(itemStart) && !itemDate.isAfter(itemEnd);
    }).toList();
  }

  // Tất cả ngày có lịch học trong học kỳ
  Set<DateTime> get allScheduledDates {
    final dates = <DateTime>{};
    if (startDate == null || endDate == null || items.isEmpty) return dates;
    final semStart = _mondayOf(startDate!);
    for (int week = 1; week <= totalWeeks; week++) {
      final wStart = semStart.add(Duration(days: (week - 1) * 7));
      if (wStart.isAfter(endDate!)) break;
      for (final item in items) {
        final d = _dateOfDayInWeek(wStart, item.dayOfWeek);
        final itemStart = item.enrollmentStartDate ?? startDate!;
        final itemEnd = item.enrollmentEndDate ?? endDate!;
        if (!d.isBefore(itemStart) && !d.isAfter(itemEnd)) {
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
