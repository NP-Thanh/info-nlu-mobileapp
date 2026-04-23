class StudentInfo {
  final String studentCode;
  final String fullName;
  final String status;

  // Thông tin sinh viên
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? idCard;
  final String? email;

  // Thông tin lý lịch
  final String? birthPlace;
  final String? ethnicity;
  final String? religion;
  final String? nationality;

  // Thông tin khóa học
  final String? major;
  final String? specialization;
  final String? classCode;
  final String? faculty;
  final String? academicYear;
  final String? degreeType;

  const StudentInfo({
    required this.studentCode,
    required this.fullName,
    required this.status,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.idCard,
    this.email,
    this.birthPlace,
    this.ethnicity,
    this.religion,
    this.nationality,
    this.major,
    this.specialization,
    this.classCode,
    this.faculty,
    this.academicYear,
    this.degreeType,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentCode: json['studentCode'] ?? '',
      fullName: json['fullName'] ?? '',
      status: json['status'] ?? 'Đang học',
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      phone: json['phone'],
      idCard: json['idCard'],
      email: json['email'],
      birthPlace: json['birthPlace'],
      ethnicity: json['ethnicity'],
      religion: json['religion'],
      nationality: json['nationality'],
      major: json['major'],
      specialization: json['specialization'],
      classCode: json['classCode'],
      faculty: json['faculty'],
      academicYear: json['academicYear'],
      degreeType: json['degreeType'],
    );
  }
}
