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

class _AdminAcademicScreenState extends State<AdminAcademicScreen> with SingleTickerProviderStateMixin {
  final _repo = AdminRepository();
  final _manualMssv = TextEditingController();
  final _manualTerm = TextEditingController();
  final _manualCourse = TextEditingController();
  final _manualProcess = TextEditingController();
  final _manualExam = TextEditingController();
  late final TabController _tabController;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _studentSuggestions = [];
  List<Map<String, dynamic>> _termOptions = [];
  List<Map<String, dynamic>> _courseOptions = [];
  String? _selectedMssv;
  String? _selectedAcademicYear;
  String? _selectedSemester;
  String? _selectedCourseCode;
  String? _importCoursePath;
  String? _importGradePath;
  bool _loadingCourses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _manualMssv.dispose();
    _manualTerm.dispose();
    _manualCourse.dispose();
    _manualProcess.dispose();
    _manualExam.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      _courses = await _repo.getCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không tải được danh sách môn học');
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _openCourseForm({Map<String, dynamic>? course}) async {
    final code = TextEditingController(text: course?['courseCode']?.toString() ?? '');
    final name = TextEditingController(text: course?['courseName']?.toString() ?? '');
    final credits = TextEditingController(text: course?['credits']?.toString() ?? '');
    final submit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(course == null ? 'Thêm môn học' : 'Cập nhật môn học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'course_code')),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'name')),
            TextField(
              controller: credits,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'credits'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
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
      _showSnack(e.response?.data?['message'] ?? 'Lưu môn học thất bại');
    }
  }

  Future<void> _deleteCourse(int id) async {
    try {
      await _repo.deleteCourse(id);
      _showSnack('Đã xóa môn học');
      _loadCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Xóa môn học thất bại');
    }
  }

  Future<void> _pickCourseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    setState(() {
      _importCoursePath = result?.files.single.path;
    });
  }

  Future<void> _pickGradeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    setState(() {
      _importGradePath = result?.files.single.path;
    });
  }

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
    _manualTerm.clear();
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
      _showSnack(e.response?.data?['message'] ?? 'Không tải được học kỳ/năm học');
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
      _showSnack(e.response?.data?['message'] ?? 'Không tải được môn học theo học kỳ');
    }
  }

  Future<void> _importCourses() async {
    if (_importCoursePath == null || _importCoursePath!.isEmpty) {
      _showSnack('Hãy chọn file Excel môn học');
      return;
    }
    try {
      final response = await _repo.importCourses(_importCoursePath!);
      _showSnack(response['message']?.toString() ?? 'Import môn học thành công');
      _loadCourses();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Import thất bại');
    }
  }

  Future<void> _saveManualGrade() async {
    if (_selectedMssv == null ||
        _selectedAcademicYear == null ||
        _selectedSemester == null ||
        _selectedCourseCode == null) {
      _showSnack('Vui lòng chọn đủ MSSV, học kỳ/năm học và môn học');
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
      _showSnack(e.response?.data?['message'] ?? 'Lưu điểm thất bại');
    }
  }

  Future<void> _importGrades() async {
    if (_selectedCourseCode == null || _selectedCourseCode!.isEmpty) {
      _showSnack('Chọn môn học trước khi import điểm');
      return;
    }
    if (_importGradePath == null || _importGradePath!.isEmpty) {
      _showSnack('Hãy chọn file Excel điểm');
      return;
    }
    try {
      final response = await _repo.importGrades(courseCode: _selectedCourseCode!, filePath: _importGradePath!);
      _showSnack(response['message']?.toString() ?? 'Import điểm thành công');
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Import điểm thất bại');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý học thuật', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Môn học'), Tab(text: 'Điểm')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCourseForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildCoursesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _importCoursePath == null ? 'Chưa chọn file Excel môn học' : 'File: $_importCoursePath',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickCourseFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Chọn file'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _importCourses,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingCourses
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _courses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = _courses[index];
                    return ListTile(
                      title: Text('${c['courseCode']} - ${c['courseName']}'),
                      subtitle: Text('Số tín chỉ: ${c['credits']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openCourseForm(course: c),
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          ),
                          IconButton(
                            onPressed: () => _deleteCourse((c['id'] as num).toInt()),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGradesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nhập điểm thủ công', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _manualMssv,
          decoration: const InputDecoration(labelText: 'MSSV'),
          onChanged: _searchStudentSuggestions,
        ),
        if (_studentSuggestions.isNotEmpty)
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
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedAcademicYear == null ? null : '$_selectedSemester|$_selectedAcademicYear',
          decoration: const InputDecoration(labelText: 'Học kỳ - Năm học'),
          items: _termOptions.map((term) {
            final semester = term['semester']?.toString() ?? '';
            final academicYear = term['academicYear']?.toString() ?? '';
            final value = '$semester|$academicYear';
            return DropdownMenuItem(
              value: value,
              child: Text('Học kỳ $semester, năm học $academicYear'),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final parts = value.split('|');
            if (parts.length != 2) return;
            setState(() {
              _selectedSemester = parts[0];
              _selectedAcademicYear = parts[1];
              _manualTerm.text = 'Học kỳ ${parts[0]}, năm học ${parts[1]}';
              _selectedCourseCode = null;
              _manualCourse.clear();
              _courseOptions = [];
            });
            _loadCoursesForTerm();
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _manualCourse,
          decoration: const InputDecoration(labelText: 'Mã môn học hoặc tên môn'),
          onChanged: (value) => _loadCoursesForTerm(keyword: value),
        ),
        if (_courseOptions.isNotEmpty)
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
        TextField(
          controller: _manualProcess,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'điểm quá trình'),
        ),
        TextField(
          controller: _manualExam,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'điểm thi'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(style: AdminTheme.primaryButtonStyle(), onPressed: _saveManualGrade, child: const Text('Lưu điểm', style: TextStyle(color: Colors.white))),
        const Divider(height: 32),
        const Text(
          'Import điểm theo file Excel (cột: mssv, academic_year, semester, điểm quá trình, điểm thi)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _importGradePath == null ? 'Chưa chọn file Excel điểm' : 'File: $_importGradePath',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickGradeFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Chọn file'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _importGrades,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Import'),
            ),
          ],
        ),
      ],
    );
  }
}

