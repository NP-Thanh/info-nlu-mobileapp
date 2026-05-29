import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/admin_repository.dart';
import '../utils/student_status.dart';
import '../widgets/admin_widgets.dart';

class AdminStudentFormScreen extends StatefulWidget {
  final Map<String, dynamic>? student;

  const AdminStudentFormScreen({super.key, this.student});

  bool get isEdit => student != null;

  @override
  State<AdminStudentFormScreen> createState() => _AdminStudentFormScreenState();
}

class _AdminStudentFormScreenState extends State<AdminStudentFormScreen> {
  final _repo = AdminRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _studentCode;
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _cccd;
  late final TextEditingController _ethnicity;
  late final TextEditingController _religion;
  late final TextEditingController _nationality;
  late final TextEditingController _placeOfBirth;
  late final TextEditingController _startYear;
  late final TextEditingController _endYear;
  late final TextEditingController _className;
  late final TextEditingController _dateOfBirth;

  String _gender = 'Nam';
  String _status = 'ACTIVE';

  String? _selectedFaculty;
  String? _selectedMajor;
  String? _selectedSpecialization;
  int? _programId;

  List<String> _faculties = [];
  List<String> _majors = [];
  List<String> _specializations = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _studentCode = TextEditingController(text: s?['studentCode']?.toString() ?? '');
    _fullName = TextEditingController(text: s?['fullName']?.toString() ?? '');
    _email = TextEditingController(text: s?['email']?.toString() ?? '');
    _phone = TextEditingController(text: s?['phone']?.toString() ?? '');
    _cccd = TextEditingController(text: s?['cccd']?.toString() ?? '');
    _ethnicity = TextEditingController(text: s?['ethnicity']?.toString() ?? 'Kinh');
    _religion = TextEditingController(text: s?['religion']?.toString() ?? 'Không');
    _nationality = TextEditingController(text: s?['nationality']?.toString() ?? 'Việt Nam');
    _placeOfBirth = TextEditingController(text: s?['placeOfBirth']?.toString() ?? '');
    _startYear = TextEditingController(text: s?['startYear']?.toString() ?? '');
    _endYear = TextEditingController(text: s?['endYear']?.toString() ?? '');
    _className = TextEditingController(text: s?['className']?.toString() ?? '');
    _dateOfBirth = TextEditingController(text: _toIsoDate(s?['dateOfBirth']?.toString()));

    if (s != null) {
      _gender = s['gender']?.toString() ?? 'Nam';
      _status = s['status']?.toString().toUpperCase() ?? 'ACTIVE';
      if (!studentStatusOptions.contains(_status)) _status = 'ACTIVE';
      _selectedFaculty = s['faculty']?.toString();
      _selectedMajor = s['major']?.toString();
      _selectedSpecialization = s['specialization']?.toString();
      _programId = (s['programId'] as num?)?.toInt();
    }

    _loadFaculties();
    if (_selectedFaculty != null) _loadMajors(_selectedFaculty!);
    if (_selectedFaculty != null && _selectedMajor != null) {
      _loadSpecializations(_selectedFaculty!, _selectedMajor!);
    }
  }

  String _toIsoDate(String? display) {
    if (display == null || display.isEmpty) return '2000-01-01';
    final parts = display.split('/');
    if (parts.length == 3) return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    return display;
  }

  Future<void> _loadFaculties() async {
    try {
      final list = await _repo.getProgramFaculties();
      if (mounted) setState(() => _faculties = list);
    } catch (_) {}
  }

  Future<void> _loadMajors(String faculty) async {
    try {
      final list = await _repo.getProgramMajors(faculty);
      if (mounted) setState(() => _majors = list);
    } catch (_) {}
  }

  Future<void> _loadSpecializations(String faculty, String major) async {
    try {
      final list = await _repo.getProgramSpecializations(faculty, major);
      if (mounted) setState(() => _specializations = list);
    } catch (_) {}
  }

  Future<void> _resolveProgram() async {
    if (_selectedFaculty == null || _selectedMajor == null || _selectedSpecialization == null) return;
    try {
      final resolved = await _repo.resolveProgram(_selectedFaculty!, _selectedMajor!, _selectedSpecialization!);
      setState(() => _programId = (resolved['programId'] as num).toInt());
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Không xác định được chương trình đào tạo');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_programId == null) {
      _showSnack('Vui lòng chọn đủ khoa → ngành → chuyên ngành');
      return;
    }

    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'gender': _gender,
      'phone': _phone.text.trim(),
      'cccd': _cccd.text.trim(),
      'ethnicity': _ethnicity.text.trim(),
      'religion': _religion.text.trim(),
      'nationality': _nationality.text.trim(),
      'placeOfBirth': _placeOfBirth.text.trim(),
      'startYear': int.parse(_startYear.text.trim()),
      'endYear': int.parse(_endYear.text.trim()),
      'status': _status,
      'dateOfBirth': _dateOfBirth.text.trim(),
      'programId': _programId,
      'className': _className.text.trim(),
    };

    try {
      if (widget.isEdit) {
        await _repo.updateStudent((widget.student!['id'] as num).toInt(), payload);
      } else {
        payload['studentCode'] = _studentCode.text.trim();
        await _repo.createStudent(payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      _showSnack(e.response?.data?['message'] ?? 'Lưu thất bại');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _studentCode.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _cccd.dispose();
    _ethnicity.dispose();
    _religion.dispose();
    _nationality.dispose();
    _placeOfBirth.dispose();
    _startYear.dispose();
    _endYear.dispose();
    _className.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminTheme.appBar(context, widget.isEdit ? 'Cập nhật sinh viên' : 'Thêm sinh viên'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminTheme.sectionTitle('Thông tin cá nhân'),
            if (!widget.isEdit) ...[
              TextFormField(
                controller: _studentCode,
                decoration: AdminTheme.inputDecoration('MSSV *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(controller: _fullName, decoration: AdminTheme.inputDecoration('Họ tên *'), validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _email, decoration: AdminTheme.inputDecoration('Email *'), validator: (v) => v == null || !v.contains('@') ? 'Email không hợp lệ' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _phone, decoration: AdminTheme.inputDecoration('Số điện thoại *'), validator: (v) => v == null || !RegExp(r'^0\d{9,10}$').hasMatch(v) ? 'SĐT không hợp lệ' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _dateOfBirth, decoration: AdminTheme.inputDecoration('Ngày sinh (yyyy-MM-dd)')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: AdminTheme.inputDecoration('Giới tính'),
              items: const [
                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'Nam'),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _cccd, decoration: AdminTheme.inputDecoration('CCCD')),
            const SizedBox(height: 10),
            TextFormField(controller: _ethnicity, decoration: AdminTheme.inputDecoration('Dân tộc')),
            const SizedBox(height: 10),
            TextFormField(controller: _religion, decoration: AdminTheme.inputDecoration('Tôn giáo')),
            const SizedBox(height: 10),
            TextFormField(controller: _nationality, decoration: AdminTheme.inputDecoration('Quốc tịch')),
            const SizedBox(height: 10),
            TextFormField(controller: _placeOfBirth, decoration: AdminTheme.inputDecoration('Nơi sinh')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startYear,
                    keyboardType: TextInputType.number,
                    decoration: AdminTheme.inputDecoration('Năm nhập học *'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Bắt buộc' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _endYear,
                    keyboardType: TextInputType.number,
                    decoration: AdminTheme.inputDecoration('Năm kết thúc *'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Bắt buộc' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: AdminTheme.inputDecoration('Trạng thái'),
              items: studentStatusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(studentStatusLabel(s))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
            ),
            const SizedBox(height: 20),
            AdminTheme.sectionTitle('Chương trình đào tạo'),
            DropdownButtonFormField<String>(
              value: _selectedFaculty,
              decoration: AdminTheme.inputDecoration('Khoa *'),
              hint: const Text('Chọn khoa'),
              items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedFaculty = v;
                  _selectedMajor = null;
                  _selectedSpecialization = null;
                  _programId = null;
                  _majors = [];
                  _specializations = [];
                });
                if (v != null) _loadMajors(v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMajor,
              decoration: AdminTheme.inputDecoration('Ngành *'),
              hint: const Text('Chọn ngành'),
              items: _majors.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: _selectedFaculty == null
                  ? null
                  : (v) {
                      setState(() {
                        _selectedMajor = v;
                        _selectedSpecialization = null;
                        _programId = null;
                        _specializations = [];
                      });
                      if (v != null && _selectedFaculty != null) _loadSpecializations(_selectedFaculty!, v);
                    },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: AdminTheme.inputDecoration('Chuyên ngành *'),
              hint: const Text('Chọn chuyên ngành'),
              items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: _selectedMajor == null
                  ? null
                  : (v) async {
                      setState(() => _selectedSpecialization = v);
                      await _resolveProgram();
                    },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _className,
              decoration: AdminTheme.inputDecoration('Lớp *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AdminTheme.primaryButtonStyle(),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEdit ? 'Cập nhật' : 'Thêm sinh viên', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
