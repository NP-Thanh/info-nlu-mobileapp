import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../model/grade_model.dart';
import '../providers/grade_provider.dart';

class GradeScreen extends ConsumerStatefulWidget {
  const GradeScreen({super.key});

  @override
  ConsumerState<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends ConsumerState<GradeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Providers are app-scoped; invalidate cached grades when re-opening screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _invalidateGradeCache());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _invalidateGradeCache() {
    ref.invalidate(gradeDataProvider);
    ref.invalidate(semesterSummaryProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(semesterListProvider);
    _invalidateGradeCache();

    final semesters = await ref.read(semesterListProvider.future);
    final current = ref.read(selectedSemesterProvider) ??
        (semesters.isNotEmpty ? semesters.first : null);
    if (current == null) return;

    await Future.wait([
      ref.read(gradeDataProvider(current).future),
      ref.read(semesterSummaryProvider(current).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final semesterListAsync = ref.watch(semesterListProvider);
    final selectedSemester = ref.watch(selectedSemesterProvider);

    // Auto-select first (latest) semester when list loads
    semesterListAsync.whenData((list) {
      if (list.isNotEmpty && selectedSemester == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedSemesterProvider.notifier).state = list.first;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: semesterListAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _buildErrorState(e.toString(), onRetry: _refresh),
        data: (semesters) {
          if (semesters.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu học kỳ',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          final current = selectedSemester ?? semesters.first;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: _buildBody(semesters, current),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.primary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Kết quả học tập',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<SemesterOption> semesters, SemesterOption current) {
    final gradeAsync = ref.watch(gradeDataProvider(current));
    final summaryAsync = ref.watch(semesterSummaryProvider(current));

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SemesterSelector(
              semesters: semesters,
              selected: current,
              onChanged: (opt) =>
                  ref.read(selectedSemesterProvider.notifier).state = opt,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: gradeAsync.when(
              loading: () => _buildSummarySkeleton(),
              error: (_, _) => _buildSummarySkeleton(),
              data: (gradeData) {
                // Dùng summary nếu có, nếu không vẫn hiển thị card với --
                final summaryOrNull = summaryAsync.valueOrNull;
                final emptySummary = SemesterSummary(
                  semester: current.semester,
                  academicYear: current.academicYear,
                );
                return _SummaryCard(
                  summary: summaryOrNull ?? emptySummary,
                  gradeData: gradeData,
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: gradeAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (gradeData) => _SectionHeader(
                title: 'Danh sách môn học',
                badge: '${gradeData.grades.length} môn',
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Course list
        gradeAsync.when(
          loading: () => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildListSkeleton(),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: _buildErrorState(e.toString()),
          ),
          data: (gradeData) => gradeData.grades.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Chưa có điểm học kỳ này',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CourseCard(item: gradeData.grades[i]),
                      ),
                      childCount: gradeData.grades.length,
                    ),
                  ),
                ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildErrorState(String msg, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySkeleton() {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;

  const _SectionHeader({required this.title, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Semester Selector ────────────────────────────────────────────────────────

class _SemesterSelector extends StatelessWidget {
  final List<SemesterOption> semesters;
  final SemesterOption selected;
  final ValueChanged<SemesterOption> onChanged;

  const _SemesterSelector({
    required this.semesters,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_outlined,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HỌC KỲ ĐANG XEM',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SemesterPickerSheet(
        semesters: semesters,
        selected: selected,
        onChanged: (opt) {
          Navigator.pop(context);
          onChanged(opt);
        },
      ),
    );
  }
}

class _SemesterPickerSheet extends StatelessWidget {
  final List<SemesterOption> semesters;
  final SemesterOption selected;
  final ValueChanged<SemesterOption> onChanged;

  const _SemesterPickerSheet({
    required this.semesters,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn học kỳ',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...semesters.map((opt) {
                    final isSelected = opt == selected;
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.school_outlined,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                      ),
                      title: Text(opt.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          )),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20)
                          : null,
                      onTap: () => onChanged(opt),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SemesterSummary summary;
  final GradeData gradeData;

  const _SummaryCard({required this.summary, required this.gradeData});

  String _fmt(double? v) => v == null ? '--' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final semCredits = summary.semesterCredits ?? gradeData.semesterCredits;
    final cumCredits = summary.cumulativeCredits;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), AppColors.primary, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tổng kết học kỳ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'HK ${summary.semester} · ${summary.academicYear}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GpaStatTile(
                        label: 'GPA hệ 4',
                        value: _fmt(summary.gpa4),
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GpaStatTile(
                        label: 'GPA hệ 10',
                        value: _fmt(summary.gpa10),
                        onDark: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tích lũy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _CumulativeChip(
                                        value: _fmt(summary.cumulativeGpa4),
                                        unit: '4',
                                        onDark: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Container(
                                          width: 1,
                                          height: 14,
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      _CumulativeChip(
                                        value: _fmt(summary.cumulativeGpa10),
                                        unit: '10',
                                        onDark: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _CreditPill(
                            label: 'HK',
                            value: '$semCredits',
                            onDark: true,
                          ),
                          const SizedBox(height: 6),
                          _CreditPill(
                            label: 'TL',
                            value: cumCredits != null ? '$cumCredits' : '--',
                            onDark: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaStatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool onDark;

  const _GpaStatTile({
    required this.label,
    required this.value,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.22)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: onDark ? Colors.white : AppColors.primary,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CumulativeChip extends StatelessWidget {
  final String value;
  final String unit;
  final bool onDark;

  const _CumulativeChip({
    required this.value,
    required this.unit,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '($unit)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: onDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _CreditPill extends StatelessWidget {
  final String label;
  final String value;
  final bool onDark;

  const _CreditPill({
    required this.label,
    required this.value,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: onDark
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          'TC',
          style: TextStyle(
            fontSize: 10,
            color: onDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final GradeItem item;

  const _CourseCard({required this.item});

  String _fmtScore(double? v) => v == null ? '--' : v.toStringAsFixed(1);

  String _letterGrade(double? score4) {
    if (score4 == null) return '--';
    if (score4 >= 3.7) return 'A+';
    if (score4 >= 3.5) return 'A';
    if (score4 >= 3.2) return 'B+';
    if (score4 >= 3.0) return 'B';
    if (score4 >= 2.7) return 'B-';
    if (score4 >= 2.3) return 'C+';
    if (score4 >= 2.0) return 'C';
    if (score4 >= 1.7) return 'C-';
    if (score4 >= 1.3) return 'D+';
    if (score4 >= 1.0) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = item.hasResult;
    final passed = item.isPassed;

    // Nếu chưa có kết quả → dùng màu neutral
    final statusColor = !hasResult
        ? AppColors.textSecondary
        : passed
            ? AppColors.primary
            : const Color(0xFFE53935);

    final letter = _letterGrade(item.finalScore4);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasResult
              ? statusColor.withValues(alpha: 0.22)
              : AppColors.textSecondary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: hasResult ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.courseCode,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.courseName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasResult ? statusColor : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: hasResult
                        ? null
                        : Border.all(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.2),
                          ),
                    boxShadow: hasResult
                        ? [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      hasResult ? letter : '--',
                      style: TextStyle(
                        fontSize: hasResult ? 17 : 16,
                        fontWeight: FontWeight.w800,
                        color: hasResult
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScoreChip(
                          label: 'Quá trình',
                          value: _fmtScore(item.processScore),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ScoreChip(
                          label: 'Thi',
                          value: _fmtScore(item.examScore),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ScoreChip(
                          label: 'Hệ 10',
                          value: _fmtScore(item.finalScore10),
                          highlight: hasResult,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ScoreChip(
                          label: 'Hệ 4',
                          value: _fmtScore(item.finalScore4),
                          highlight: hasResult,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasResult)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          passed ? 'ĐẠT' : 'NỢ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'Chưa có',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.credits} tín chỉ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const _ScoreChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final bg = highlight
        ? accent.withValues(alpha: 0.1)
        : AppColors.background;
    final textColor = highlight ? accent : AppColors.textPrimary;
    final borderColor = highlight
        ? accent.withValues(alpha: 0.25)
        : AppColors.textSecondary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 14 : 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

