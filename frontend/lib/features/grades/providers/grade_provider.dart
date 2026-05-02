import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grade_repository.dart';
import '../model/grade_model.dart';

final gradeRepositoryProvider =
    Provider<GradeRepository>((_) => GradeRepository());

final semesterListProvider =
    FutureProvider<List<SemesterOption>>((ref) async {
  return ref.watch(gradeRepositoryProvider).getAllSemesters();
});

final selectedSemesterProvider =
    StateProvider<SemesterOption?>((ref) => null);

final gradeDataProvider =
    FutureProvider.family<GradeData, SemesterOption>((ref, opt) async {
  return ref
      .watch(gradeRepositoryProvider)
      .getGrades(opt.academicYear, opt.semester);
});

final semesterSummaryProvider =
    FutureProvider.family<SemesterSummary, SemesterOption>((ref, opt) async {
  return ref
      .watch(gradeRepositoryProvider)
      .getSemesterSummary(opt.academicYear, opt.semester);
});
