import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/schedule_repository.dart';
import '../model/schedule_model.dart';

final scheduleRepositoryProvider =
    Provider<ScheduleRepository>((_) => ScheduleRepository());

final latestScheduleProvider = FutureProvider<ScheduleData>((ref) async {
  return ref.watch(scheduleRepositoryProvider).getLatestSchedule();
});

final allSemestersProvider = FutureProvider<List<ScheduleData>>((ref) async {
  return ref.watch(scheduleRepositoryProvider).getAllSemesters();
});
