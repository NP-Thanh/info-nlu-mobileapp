// admin_academic_screen.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

class AdminAcademicScreen extends StatefulWidget {
  const AdminAcademicScreen({super.key});

  @override
  State<AdminAcademicScreen> createState() => _AdminAcademicScreenState();
}

class _AdminAcademicScreenState extends State<AdminAcademicScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  late final TabController _tabController;

  // ── Courses tab ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  final _courseSearchCtrl = TextEditingController();
  bool _loadingCourses = true;
  String? _importCoursePath;
  String? _importCourseFileName;

  // ── Grades tab ───────────────────────────────────────────────────────────
  final _manualMssv = TextEditingController();
  final _manualCourse = TextEditingController();
  final _manualProcess = TextEditingController();
  final _manualExam = TextEditingController();

  List<Map<String, dynamic>> _studentSuggestions = [];
  List<Map<String, dynamic>> _termOptions = [];
  List<Map<String, dynamic>> _courseOptions = [];
  String? _selectedMssv;
  String? _selectedAcademicYear;
  String? _selectedSemester;
  String? _selectedCourseCode;

  // Import grades
  String? _importGradePath;
  String? _importGradeFileName;
  // Dropdown chọn môn học khi import điểm
  Map<String, dynamic>? _importGradeCourse;
  final _importGradeCourseCtrl = TextEditingController();
  List<Map<String, dynamic>> _importGradeCourseOptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
    _courseSearchCtrl.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _courseSearchCtrl.dispose();
    _manualMssv.dispose();
    _manualCourse.dispose();
    _manualProcess.dispose();
    _manualExam.dispose();
    _importGradeCourseCtrl.dispose();
    super.dispose();
  }

  // ── Courses ──────────────────────────────────────────────────────────────

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      _courses = await _repo.getCourses();
      _filterCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách môn học', isError: true);
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  void _filterCourses() {
    final q = _courseSearchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredCourses = q.isEmpty
          ? List.from(_courses)
          : _courses.where((c) {
              final code = (c['courseCode'] ?? '').toString().toLowerCase();
              final name = (c['courseName'] ?? '').toString().toLowerCase();
              return code.contains(q) || name.contains(q);
            }).toList();
    });
  }

  Future<void> _openCourseForm({Map<String, dynamic>? course}) async {
    final code = TextEditingController(text: course?['courseCode']?.toString() ?? '');
    final name = TextEditingController(text: course?['courseName']?.toString() ?? '');
    final credits = TextEditingController(text: course?['credits']?.toString() ?? '');
    final submit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          course == null ? 'Thêm môn học' : 'Cập nhật môn học',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              decoration: AdminTheme.inputDecoration('Mã môn học'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              decoration: AdminTheme.inputDecoration('Tên môn học'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: credits,
              keyboardType: TextInputType.number,
              decoration: AdminTheme.inputDecoration('Số tín chỉ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: AdminTheme.primaryButtonStyle(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (submit != true) return;
    final payload = {
      'course_code': code.text.trim(),
      'name': name.text.trim(),
      'credits': int.tryParse(credits.text.trim()),
    };
    try {
      if (course == null) {
        await _repo.createCourse(payload);
      } else {
        await _repo.updateCourse((course['id'] as num).toInt(), payload);
      }
      _showSnack('Lưu môn học thành công');
      _loadCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu môn học thất bại', isError: true);
    }
  }

  Future<void> _deleteCourse(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa môn học'),
        content: Text('Xóa môn "$name"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteCourse(id);
      _showSnack('Đã xóa môn học');
      _loadCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa môn học thất bại', isError: true);
    }
  }

  Future<void> _pickCourseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null) {
      setState(() {
        _importCoursePath = result.files.single.path;
        _importCourseFileName = result.files.single.name;
      });
    }
  }

  Future<void> _previewAndImportCourses() async {
    if (_importCoursePath == null) {
      _showSnack('Hãy chọn file Excel môn học', isError: true);
      return;
    }
    try {
      final preview = await _repo.previewCourses(_importCoursePath!);
      if (!mounted) return;
      final confirmed = await _showCoursePreviewDialog(preview);
      if (confirmed != true) return;
      final response = await _repo.importCourses(_importCoursePath!);
      final data = response['data'] as Map? ?? {};
      _showSnack('Import thành công ${data['successCount'] ?? 0} môn học');
      setState(() {
        _importCoursePath = null;
        _importCourseFileName = null;
      });
      _loadCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Import thất bại', isError: true);
    }
  }

  Future<bool?> _showCoursePreviewDialog(Map<String, dynamic> preview) {
    final rows = (preview['rows'] as List? ?? []).cast<Map>();
    final validCount = preview['validCount'] as int? ?? 0;
    final invalidCount = preview['invalidCount'] as int? ?? 0;
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _ImportPreviewDialog(
          title: 'Preview import môn học',
          validCount: validCount,
          invalidCount: invalidCount,
          columns: const ['Dòng', 'Mã MH', 'Tên môn học', 'TC', 'Trạng thái'],
          rows: rows.map((r) {
            final valid = r['valid'] == true;
            return _PreviewRow(
              cells: [
                r['row']?.toString() ?? '',
                r['courseCode']?.toString() ?? '',
                r['courseName']?.toString() ?? '',
                r['credits']?.toString() ?? '',
                valid ? '✓ Hợp lệ' : '✗ ${r['error'] ?? ''}',
              ],
              isValid: valid,
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Grades ───────────────────────────────────────────────────────────────

  Future<void> _searchStudentSuggestions(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() => _studentSuggestions = []);
      return;
    }
    try {
      final data = await _repo.searchStudentSuggestions(keyword);
      if (!mounted) return;
      setState(() => _studentSuggestions = data);
    } catch (_) {}
  }

  Future<void> _loadTermsForStudent(String mssv) async {
    _manualCourse.clear();
    setState(() {
      _selectedMssv = mssv;
      _selectedAcademicYear = null;
      _selectedSemester = null;
      _selectedCourseCode = null;
      _termOptions = [];
      _courseOptions = [];
    });
    try {
      final terms = await _repo.getStudentTerms(mssv);
      if (!mounted) return;
      setState(() => _termOptions = terms);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được học kỳ/năm học', isError: true);
    }
  }

  Future<void> _loadCoursesForTerm({String keyword = ''}) async {
    if (_selectedMssv == null || _selectedAcademicYear == null || _selectedSemester == null) return;
    try {
      final courses = await _repo.getStudentCoursesByTerm(
        mssv: _selectedMssv!,
        academicYear: _selectedAcademicYear!,
        semester: _selectedSemester!,
        keyword: keyword,
      );
      if (!mounted) return;
      setState(() => _courseOptions = courses);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được môn học theo học kỳ', isError: true);
    }
  }

  Future<void> _saveManualGrade() async {
    if (_selectedMssv == null ||
        _selectedAcademicYear == null ||
        _selectedSemester == null ||
        _selectedCourseCode == null) {
      _showSnack('Vui lòng chọn đủ MSSV, học kỳ/năm học và môn học', isError: true);
      return;
    }
    try {
      final response = await _repo.saveManualGrade({
        'mssv': _selectedMssv,
        'academic_year': _selectedAcademicYear,
        'semester': _selectedSemester,
        'course_code': _selectedCourseCode,
        'process_score': double.tryParse(_manualProcess.text.trim()),
        'exam_score': double.tryParse(_manualExam.text.trim()),
      });
      _showSnack(response['message']?.toString() ?? 'Lưu điểm thành công');
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu điểm thất bại', isError: true);
    }
  }

  Future<void> _pickGradeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null) {
      setState(() {
        _importGradePath = result.files.single.path;
        _importGradeFileName = result.files.single.name;
      });
    }
  }

  Future<void> _searchImportGradeCourse(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() => _importGradeCourseOptions = []);
      return;
    }
    final q = keyword.toLowerCase();
    setState(() {
      _importGradeCourseOptions = _courses.where((c) {
        final code = (c['courseCode'] ?? '').toString().toLowerCase();
        final name = (c['courseName'] ?? '').toString().toLowerCase();
        return code.contains(q) || name.contains(q);
      }).take(10).toList();
    });
  }

  Future<void> _previewAndImportGrades() async {
    if (_importGradeCourse == null) {
      _showSnack('Chọn môn học trước khi import điểm', isError: true);
      return;
    }
    if (_importGradePath == null) {
      _showSnack('Hãy chọn file Excel điểm', isError: true);
      return;
    }
    final courseCode = _importGradeCourse!['courseCode']?.toString() ?? '';
    try {
      final preview = await _repo.previewGrades(courseCode: courseCode, filePath: _importGradePath!);
      if (!mounted) return;
      final confirmed = await _showGradePreviewDialog(preview, courseCode);
      if (confirmed != true) return;
      final response = await _repo.importGrades(courseCode: courseCode, filePath: _importGradePath!);
      final data = response['data'] as Map? ?? {};
      _showSnack('Import thành công ${data['successCount'] ?? 0} dòng điểm');
      setState(() {
        _importGradePath = null;
        _importGradeFileName = null;
      });
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Import điểm thất bại', isError: true);
    }
  }

  Future<bool?> _showGradePreviewDialog(Map<String, dynamic> preview, String courseCode) {
    final rows = (preview['rows'] as List? ?? []).cast<Map>();
    final validCount = preview['validCount'] as int? ?? 0;
    final invalidCount = preview['invalidCount'] as int? ?? 0;
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _ImportPreviewDialog(
          title: 'Preview import điểm — $courseCode',
          validCount: validCount,
          invalidCount: invalidCount,
          columns: const ['Dòng', 'MSSV', 'Năm học', 'HK', 'QT', 'Thi', 'Trạng thái'],
          rows: rows.map((r) {
            final valid = r['valid'] == true;
            return _PreviewRow(
              cells: [
                r['row']?.toString() ?? '',
                r['studentCode']?.toString() ?? '',
                r['academicYear']?.toString() ?? '',
                r['semester']?.toString() ?? '',
                r['processScore']?.toString() ?? '',
                r['examScore']?.toString() ?? '',
                valid ? '✓ Hợp lệ' : '✗ ${r['error'] ?? ''}',
              ],
              isValid: valid,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Quản lý học thuật',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.border),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Môn học'),
                  Tab(text: 'Điểm'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _openCourseForm(),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm môn', style: TextStyle(color: Colors.white)),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCoursesTab(),
          _buildGradesTab(),
        ],
      ),
    );
  }

  // ── Courses Tab ───────────────────────────────────────────────────────────

  Widget _buildCoursesTab() {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _courseSearchCtrl,
            decoration: AdminTheme.inputDecoration(
              'Tìm môn học theo mã hoặc tên...',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
          ),
        ),
        // Import bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _importCourseFileName ?? 'Chưa chọn file Excel',
                          style: TextStyle(
                            fontSize: 13,
                            color: _importCourseFileName != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: AdminTheme.outlinedButtonStyle(),
                onPressed: _pickCourseFile,
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('Chọn'),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: AdminTheme.primaryButtonStyle(),
                onPressed: _previewAndImportCourses,
                icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                label: const Text('Import', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.border),
        // Stats bar
        if (!_loadingCourses)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredCourses.length} môn học',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_courseSearchCtrl.text.isNotEmpty) ...[
                  const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    'lọc từ ${_courses.length} môn',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        // List
        Expanded(
          child: _loadingCourses
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredCourses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 48, color: AppColors.border),
                          const SizedBox(height: 12),
                          Text(
                            _courseSearchCtrl.text.isEmpty
                                ? 'Chưa có môn học nào'
                                : 'Không tìm thấy môn học',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCourses,
                      color: AppColors.primary,
                      child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _filteredCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = _filteredCourses[index];
                        return _CourseCard(
                          course: c,
                          query: _courseSearchCtrl.text,
                          onEdit: () => _openCourseForm(course: c),
                          onDelete: () => _deleteCourse(
                            (c['id'] as num).toInt(),
                            c['courseName']?.toString() ?? '',
                          ),
                        );
                      },
                    ),
                    ),
        ),
      ],
    );
  }

  // ── Grades Tab ────────────────────────────────────────────────────────────

  Widget _buildGradesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Manual grade section ──────────────────────────────────────────
        _SectionHeader(
          icon: Icons.edit_note_outlined,
          title: 'Nhập điểm thủ công',
        ),
        const SizedBox(height: 12),
        _GradeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MSSV field
              TextField(
                controller: _manualMssv,
                decoration: AdminTheme.inputDecoration(
                  'MSSV sinh viên',
                  prefixIcon: const Icon(Icons.person_search_outlined, size: 20),
                ),
                onChanged: _searchStudentSuggestions,
              ),
              if (_studentSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                AdminSuggestionCardFromMaps(
                  items: _studentSuggestions,
                  query: _manualMssv.text,
                  displayBuilder: (item) => '${item['studentCode']} - ${item['fullName']}',
                  onSelect: (item) {
                    final mssv = item['studentCode']?.toString() ?? '';
                    setState(() {
                      _manualMssv.text = mssv;
                      _studentSuggestions = [];
                    });
                    _loadTermsForStudent(mssv);
                  },
                ),
              ],
              const SizedBox(height: 10),
              // Term dropdown
              DropdownButtonFormField<String>(
                value: _selectedAcademicYear == null
                    ? null
                    : '$_selectedSemester|$_selectedAcademicYear',
                decoration: AdminTheme.inputDecoration(
                  'Học kỳ - Năm học',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                hint: const Text('Chọn học kỳ'),
                items: _termOptions.map((term) {
                  final semester = term['semester']?.toString() ?? '';
                  final academicYear = term['academicYear']?.toString() ?? '';
                  return DropdownMenuItem(
                    value: '$semester|$academicYear',
                    child: Text('HK $semester — $academicYear'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final parts = value.split('|');
                  if (parts.length != 2) return;
                  setState(() {
                    _selectedSemester = parts[0];
                    _selectedAcademicYear = parts[1];
                    _selectedCourseCode = null;
                    _manualCourse.clear();
                    _courseOptions = [];
                  });
                  _loadCoursesForTerm();
                },
              ),
              const SizedBox(height: 10),
              // Course search
              TextField(
                controller: _manualCourse,
                decoration: AdminTheme.inputDecoration(
                  'Mã hoặc tên môn học',
                  prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                ),
                onChanged: (v) => _loadCoursesForTerm(keyword: v),
              ),
              if (_courseOptions.isNotEmpty) ...[
                const SizedBox(height: 4),
                AdminSuggestionCardFromMaps(
                  items: _courseOptions,
                  query: _manualCourse.text,
                  displayBuilder: (item) => item['display']?.toString() ?? '',
                  onSelect: (item) {
                    setState(() {
                      _selectedCourseCode = item['courseCode']?.toString();
                      _manualCourse.text = item['display']?.toString() ?? '';
                      _courseOptions = [];
                    });
                  },
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualProcess,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: AdminTheme.inputDecoration('Điểm quá trình'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _manualExam,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: AdminTheme.inputDecoration('Điểm thi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: AdminTheme.primaryButtonStyle(),
                  onPressed: _saveManualGrade,
                  icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  label: const Text('Lưu điểm', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Import grades section ─────────────────────────────────────────
        _SectionHeader(
          icon: Icons.upload_file_outlined,
          title: 'Import điểm từ Excel',
          subtitle: 'Cột: mssv | năm học | học kỳ | điểm QT | điểm thi',
        ),
        const SizedBox(height: 12),
        _GradeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chọn môn học để import
              TextField(
                controller: _importGradeCourseCtrl,
                decoration: AdminTheme.inputDecoration(
                  'Chọn môn học cần import điểm',
                  prefixIcon: const Icon(Icons.menu_book_outlined, size: 20),
                  hint: 'Nhập mã hoặc tên môn...',
                ),
                onChanged: _searchImportGradeCourse,
              ),
              if (_importGradeCourse != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_importGradeCourse!['courseCode']} — ${_importGradeCourse!['courseName']}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _importGradeCourse = null;
                          _importGradeCourseCtrl.clear();
                        }),
                        child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
              if (_importGradeCourseOptions.isNotEmpty) ...[
                const SizedBox(height: 4),
                AdminSuggestionCardFromMaps(
                  items: _importGradeCourseOptions,
                  query: _importGradeCourseCtrl.text,
                  displayBuilder: (item) =>
                      '${item['courseCode']} — ${item['courseName']}',
                  onSelect: (item) {
                    setState(() {
                      _importGradeCourse = item;
                      _importGradeCourseCtrl.text =
                          '${item['courseCode']} — ${item['courseName']}';
                      _importGradeCourseOptions = [];
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              // File picker
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _importGradeFileName ?? 'Chưa chọn file Excel',
                              style: TextStyle(
                                fontSize: 13,
                                color: _importGradeFileName != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: AdminTheme.outlinedButtonStyle(),
                    onPressed: _pickGradeFile,
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: const Text('Chọn'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: AdminTheme.primaryButtonStyle(),
                  onPressed: _previewAndImportGrades,
                  icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                  label: const Text('Preview & Import', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  final Widget child;
  const _GradeCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final String query;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.query,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final code = course['courseCode']?.toString() ?? '';
    final name = course['courseName']?.toString() ?? '';
    final credits = course['credits']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 18),
        ),
        title: AdminHighlightedText(text: '$code — $name', query: query),
        subtitle: Text(
          '$credits tín chỉ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              tooltip: 'Chỉnh sửa',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade600),
              tooltip: 'Xóa',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview dialog ────────────────────────────────────────────────────────────

class _PreviewRow {
  final List<String> cells;
  final bool isValid;
  const _PreviewRow({required this.cells, required this.isValid});
}

class _ImportPreviewDialog extends StatelessWidget {
  final String title;
  final int validCount;
  final int invalidCount;
  final List<String> columns;
  final List<_PreviewRow> rows;

  const _ImportPreviewDialog({
    required this.title,
    required this.validCount,
    required this.invalidCount,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        maxWidth: MediaQuery.sizeOf(context).width * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatChip(
                  label: '$validCount hợp lệ',
                  color: Colors.green.shade600,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '$invalidCount lỗi',
                  color: invalidCount > 0 ? Colors.red.shade600 : AppColors.textSecondary,
                  icon: Icons.error_outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          // Table
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 52,
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(AppColors.surface),
                  columns: columns
                      .map((c) => DataColumn(
                            label: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ))
                      .toList(),
                  rows: rows.map((r) {
                    return DataRow(
                      color: WidgetStateProperty.all(
                        r.isValid
                            ? Colors.transparent
                            : Colors.red.shade50,
                      ),
                      cells: r.cells.asMap().entries.map((entry) {
                        final isLast = entry.key == r.cells.length - 1;
                        return DataCell(
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLast
                                  ? (r.isValid
                                      ? Colors.green.shade700
                                      : Colors.red.shade700)
                                  : AppColors.textPrimary,
                              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: AdminTheme.outlinedButtonStyle(),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: validCount == 0
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppColors.border,
                          foregroundColor: AppColors.textSecondary,
                        )
                      : AdminTheme.primaryButtonStyle(),
                  onPressed: validCount == 0 ? null : () => Navigator.pop(context, true),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                  label: Text(
                    'Import $validCount dòng',
                    style: const TextStyle(color: Colors.white),
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

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
