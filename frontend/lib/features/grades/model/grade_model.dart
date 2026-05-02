class GradeItem {
  final String courseCode;
  final String courseName;
  final int credits;
  final double? processScore;
  final double? examScore;
  final double? finalScore10;
  final double? finalScore4;
  final String? result;

  const GradeItem({
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.processScore,
    this.examScore,
    this.finalScore10,
    this.finalScore4,
    this.result,
  });

  bool get isPassed {
    if (result == null) return false;
    final r = result!.trim().toLowerCase();
    return r == 'passed' || r == 'đạt';
  }

  bool get hasResult => result != null && result!.trim().isNotEmpty;

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      credits: json['credits'] ?? 0,
      processScore: (json['processScore'] as num?)?.toDouble(),
      examScore: (json['examScore'] as num?)?.toDouble(),
      finalScore10: (json['finalScore10'] as num?)?.toDouble(),
      finalScore4: (json['finalScore4'] as num?)?.toDouble(),
      result: json['result'],
    );
  }
}

class GradeData {
  final String semester;
  final String academicYear;
  final List<GradeItem> grades;

  const GradeData({
    required this.semester,
    required this.academicYear,
    required this.grades,
  });

  int get semesterCredits =>
      grades.where((g) => g.isPassed).fold(0, (sum, g) => sum + g.credits);

  factory GradeData.fromJson(Map<String, dynamic> json) {
    return GradeData(
      semester: json['semester'] ?? '',
      academicYear: json['academicYear'] ?? '',
      grades: (json['grades'] as List<dynamic>? ?? [])
          .map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SemesterSummary {
  final String semester;
  final String academicYear;
  final double? gpa10;
  final double? gpa4;
  final double? cumulativeGpa10;
  final double? cumulativeGpa4;
  final int? semesterCredits;
  final int? cumulativeCredits;

  const SemesterSummary({
    required this.semester,
    required this.academicYear,
    this.gpa10,
    this.gpa4,
    this.cumulativeGpa10,
    this.cumulativeGpa4,
    this.semesterCredits,
    this.cumulativeCredits,
  });

  factory SemesterSummary.fromJson(Map<String, dynamic> json) {
    return SemesterSummary(
      semester: json['semester'] ?? '',
      academicYear: json['academicYear'] ?? '',
      gpa10: (json['gpa10'] as num?)?.toDouble(),
      gpa4: (json['gpa4'] as num?)?.toDouble(),
      cumulativeGpa10: (json['cumulativeGpa10'] as num?)?.toDouble(),
      cumulativeGpa4: (json['cumulativeGpa4'] as num?)?.toDouble(),
      semesterCredits: json['semesterCredits'] as int?,
      cumulativeCredits: json['cumulativeCredits'] as int?,
    );
  }
}

class SemesterOption {
  final String semester;
  final String academicYear;

  const SemesterOption({required this.semester, required this.academicYear});

  String get label => 'Học kỳ $semester ($academicYear)';

  @override
  bool operator ==(Object other) =>
      other is SemesterOption &&
      other.semester == semester &&
      other.academicYear == academicYear;

  @override
  int get hashCode => Object.hash(semester, academicYear);
}
