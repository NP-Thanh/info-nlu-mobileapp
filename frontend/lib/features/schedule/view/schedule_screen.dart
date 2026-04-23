import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/schedule_repository.dart';
import '../model/schedule_model.dart';
import '../providers/schedule_provider.dart';
import 'widgets/schedule_header_card.dart';
import 'widgets/schedule_day_section.dart';
import 'widgets/schedule_calendar_sheet.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  ScheduleData? _scheduleData;
  int _currentWeek = 1;
  bool _isLoading = true;
  String? _error;
  ScheduleRepository? _repo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = ref.read(scheduleRepositoryProvider);
      _loadLatest();
    });
  }

  Future<void> _loadLatest() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _repo!.getLatestSchedule();
      final week = data.currentWeek(DateTime.now());
      setState(() {
        _scheduleData = data;
        _currentWeek = week;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _prevWeek() {
    if (_currentWeek > 1) setState(() => _currentWeek--);
  }

  void _nextWeek() {
    final total = _scheduleData?.totalWeeks ?? 1;
    if (_currentWeek < total) setState(() => _currentWeek++);
  }

  void _onCalendarDaySelected(DateTime date) {
    if (_scheduleData == null) return;
    final week = _scheduleData!.weekOfDate(date);
    setState(() => _currentWeek = week);
  }

  void _showCalendar() {
    if (_scheduleData == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleCalendarSheet(
        scheduleData: _scheduleData!,
        currentWeek: _currentWeek,
        onDaySelected: (date) {
          Navigator.pop(context);
          _onCalendarDaySelected(date);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Thời khóa biểu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('Không thể tải thời khóa biểu',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadLatest,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final data = _scheduleData!;
    final weekItems = data.itemsForWeek(_currentWeek);
    final wStart = data.weekStart(_currentWeek);
    final wEnd = data.weekEnd(_currentWeek);

    // Group by dayOfWeek, sort items by period (1→4) within each day
    final Map<int, List<ScheduleItem>> byDay = {};
    for (final item in weekItems) {
      byDay.putIfAbsent(item.dayOfWeek, () => []).add(item);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.period.compareTo(b.period));
    }

    // Days to show: Mon(2) to Sun(8)
    final days = List.generate(7, (i) => i + 2);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadLatest,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ScheduleHeaderCard(
                scheduleData: data,
                currentWeek: _currentWeek,
                weekStart: wStart,
                weekEnd: wEnd,
                onPrev: _currentWeek > 1 ? _prevWeek : null,
                onNext: _currentWeek < data.totalWeeks ? _nextWeek : null,
                onCalendar: _showCalendar,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dow = days[index];
                final dayDate = _dateOfDayInWeek(wStart, dow);
                final dayItems = byDay[dow] ?? [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ScheduleDaySection(
                        dayOfWeek: dow,
                        date: dayDate,
                        items: dayItems,
                      ),
                    ),
                    if (index < days.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE8EDE8)),
                  ],
                );
              },
              childCount: days.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static DateTime _dateOfDayInWeek(DateTime monday, int dayOfWeek) {
    final offset = dayOfWeek == 8 ? 6 : dayOfWeek - 2;
    return monday.add(Duration(days: offset));
  }
}
