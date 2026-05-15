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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(semesterListProvider);
    ref.invalidate(selectedSemesterProvider);
    await ref.read(semesterListProvider.future);
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
              error: (_, __) => _buildSummarySkeleton(),
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
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: gradeAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (gradeData) => _SectionHeader(
                title: 'Danh sách môn học',
                badge: '${gradeData.grades.length} môn',
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600),
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
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Top: GPA học kỳ
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildGpaBlock(
                    label: 'GPA Học Kỳ',
                    sub: 'Hệ 4',
                    value: _fmt(summary.gpa4),
                    large: true,
                  ),
                ),
                Container(
                    width: 1, height: 56, color: Colors.white.withOpacity(0.25)),
                Expanded(
                  child: _buildGpaBlock(
                    label: 'GPA Học Kỳ',
                    sub: 'Hệ 10',
                    value: _fmt(summary.gpa10),
                    large: true,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withOpacity(0.2),
          ),

          // Bottom: tích lũy + tín chỉ
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildSmallBlock(
                      label: 'Tích Lũy (Hệ 4)',
                      value: _fmt(summary.cumulativeGpa4)),
                ),
                Expanded(
                  child: _buildSmallBlock(
                      label: 'Tích Lũy (Hệ 10)',
                      value: _fmt(summary.cumulativeGpa10)),
                ),
                Expanded(
                  child: _buildSmallBlock(
                      label: 'TC Học Kỳ', value: '$semCredits'),
                ),
                Expanded(
                  child: _buildSmallBlock(
                      label: 'TC Tích Lũy',
                      value: cumCredits != null ? '$cumCredits' : '--'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaBlock(
      {required String label,
      required String sub,
      required String value,
      bool large = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 36 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            sub,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBlock({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.courseCode,
                        style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.courseName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Letter grade badge — chỉ hiện khi có điểm
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasResult ? statusColor : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      hasResult ? letter : '--',
                      style: TextStyle(
                          fontSize: hasResult ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: hasResult
                              ? Colors.white
                              : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Score row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _ScoreChip(
                  label: 'Quá trình',
                  value: _fmtScore(item.processScore),
                ),
                const SizedBox(width: 8),
                _ScoreChip(
                  label: 'Thi',
                  value: _fmtScore(item.examScore),
                ),
                const SizedBox(width: 8),
                _ScoreChip(
                  label: 'Hệ 10',
                  value: _fmtScore(item.finalScore10),
                  highlight: hasResult,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                _ScoreChip(
                  label: 'Hệ 4',
                  value: _fmtScore(item.finalScore4),
                  highlight: hasResult,
                  color: statusColor,
                ),
                const Spacer(),
                // Credits + status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasResult)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          passed ? 'ĐẠT' : 'NỢ',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Chưa có',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.credits} TC',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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
    final bg = highlight
        ? (color ?? AppColors.primary).withOpacity(0.08)
        : AppColors.background;
    final textColor =
        highlight ? (color ?? AppColors.primary) : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ],
      ),
    );
  }
}

