import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/student_repository.dart';
import '../model/student_info.dart';

final studentRepositoryProvider = Provider<StudentRepository>((_) => StudentRepository());

final studentInfoProvider = FutureProvider<StudentInfo>((ref) async {
  return ref.watch(studentRepositoryProvider).getStudentInfo();
});
