package com.example.nlu.service;

import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.response.AdminStudentDetailResponse;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.entity.*;
import com.example.nlu.repo.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminStudentService {

    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;
    private final UserRepository userRepository;
    private final ProgramRepository programRepository;
    private final PasswordEncoder passwordEncoder;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public List<AdminStudentResponse> getStudents(String keyword,
                                                   String className,
                                                   String faculty,
                                                   Integer startYear,
                                                   String status) {
        StudentStatus statusFilter = isBlank(status) ? null : parseStatus(status);
        List<Student> students = studentRepository.searchStudents(
                isBlank(keyword) ? null : keyword.trim(),
                startYear,
                statusFilter
        );

        if (!isBlank(className) || !isBlank(faculty)) {
            List<Long> validIds = studentProgramRepository.findStudentIdsByClassNameAndFaculty(
                    isBlank(className) ? null : className.trim(),
                    isBlank(faculty) ? null : faculty.trim()
            );
            students = students.stream()
                    .filter(s -> validIds.contains(s.getId()))
                    .collect(Collectors.toList());
        }

        return students.stream().map(this::toListResponse).collect(Collectors.toList());
    }

    public AdminStudentDetailResponse getStudentDetail(Long id) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên với id: " + id));
        return toDetailResponse(student);
    }

    public List<String> getFilterSuggestions(String type, String keyword) {
        String kw = isBlank(keyword) ? null : keyword.trim();
        return switch (type == null ? "" : type.toLowerCase()) {
            case "classname", "class" -> studentProgramRepository.suggestClassNames(kw).stream()
                    .limit(20)
                    .collect(Collectors.toList());
            case "faculty" -> studentProgramRepository.suggestFaculties(kw).stream()
                    .limit(20)
                    .collect(Collectors.toList());
            case "startyear", "year" -> studentRepository.findDistinctStartYears().stream()
                    .filter(y -> kw == null || String.valueOf(y).contains(kw))
                    .limit(20)
                    .map(String::valueOf)
                    .collect(Collectors.toList());
            default -> throw new IllegalArgumentException("Loại bộ lọc không hợp lệ: " + type);
        };
    }

    @Transactional
    public AdminStudentResponse createStudent(CreateStudentRequest req) {
        if (isBlank(req.getStudentCode()))
            throw new IllegalArgumentException("Mã sinh viên không được để trống");
        if (isBlank(req.getEmail()))
            throw new IllegalArgumentException("Email không được để trống");
        if (req.getProgramId() == null)
            throw new IllegalArgumentException("Vui lòng chọn chương trình đào tạo (khoa - ngành - chuyên ngành)");
        if (isBlank(req.getClassName()))
            throw new IllegalArgumentException("Lớp không được để trống");

        if (studentRepository.findByStudentCode(req.getStudentCode()).isPresent())
            throw new IllegalArgumentException("Mã sinh viên đã tồn tại: " + req.getStudentCode());
        if (userRepository.findByUsername(req.getStudentCode()).isPresent())
            throw new IllegalArgumentException("Tài khoản đã tồn tại: " + req.getStudentCode());

        validateStudentFields(req.getFullName(), req.getDateOfBirth(), req.getGender(),
                req.getPhone(), req.getStartYear(), req.getEndYear());

        Program program = programRepository.findById(req.getProgramId())
                .orElseThrow(() -> new IllegalArgumentException("Chương trình đào tạo không tồn tại"));

        User user = new User();
        user.setUsername(req.getStudentCode());
        user.setPassword(passwordEncoder.encode(req.getStudentCode()));
        user.setEmail(req.getEmail());
        user.setRole(Role.STUDENT);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        Student student = buildStudentFromCreate(req, user);
        studentRepository.save(student);

        StudentProgram sp = new StudentProgram();
        sp.setStudent(student);
        sp.setProgram(program);
        sp.setClassName(req.getClassName().trim());
        sp.setStartYear(req.getStartYear());
        sp.setEndYear(req.getEndYear());
        studentProgramRepository.save(sp);

        return toListResponse(student);
    }

    @Transactional
    public AdminStudentResponse updateStudent(Long id, UpdateStudentRequest req) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên với id: " + id));

        validateStudentFields(req.getFullName(), req.getDateOfBirth(), req.getGender(),
                req.getPhone(), req.getStartYear(), req.getEndYear());

        if (!isBlank(req.getFullName())) student.setFullName(req.getFullName());
        if (req.getDateOfBirth() != null) student.setDateOfBirth(req.getDateOfBirth());
        if (!isBlank(req.getGender())) student.setGender(req.getGender());
        if (!isBlank(req.getPhone())) student.setPhone(req.getPhone());
        if (!isBlank(req.getCccd())) student.setCccd(req.getCccd());
        if (!isBlank(req.getEthnicity())) student.setEthnicity(req.getEthnicity());
        if (!isBlank(req.getReligion())) student.setReligion(req.getReligion());
        if (!isBlank(req.getNationality())) student.setNationality(req.getNationality());
        if (!isBlank(req.getPlaceOfBirth())) student.setPlaceOfBirth(req.getPlaceOfBirth());
        if (req.getStartYear() != null) student.setStartYear(req.getStartYear());
        if (req.getEndYear() != null) student.setEndYear(req.getEndYear());
        if (!isBlank(req.getStatus())) student.setStatus(parseStatus(req.getStatus()));

        if (!isBlank(req.getEmail()) && student.getUser() != null) {
            student.getUser().setEmail(req.getEmail());
            userRepository.save(student.getUser());
        }

        studentRepository.save(student);

        if (req.getProgramId() != null || !isBlank(req.getClassName())) {
            StudentProgram sp = studentProgramRepository.findFirstByStudent_Id(id)
                    .orElse(new StudentProgram());
            sp.setStudent(student);
            if (req.getProgramId() != null) {
                Program program = programRepository.findById(req.getProgramId())
                        .orElseThrow(() -> new IllegalArgumentException("Chương trình đào tạo không tồn tại"));
                sp.setProgram(program);
            }
            if (!isBlank(req.getClassName())) sp.setClassName(req.getClassName().trim());
            if (req.getStartYear() != null) sp.setStartYear(req.getStartYear());
            if (req.getEndYear() != null) sp.setEndYear(req.getEndYear());
            studentProgramRepository.save(sp);
        }

        return toListResponse(student);
    }

    @Transactional
    public void deleteStudent(Long id) {
        blockStudents(List.of(id));
    }

    @Transactional
    public int deleteStudentsBulk(List<Long> ids) {
        if (ids == null || ids.isEmpty())
            throw new IllegalArgumentException("Danh sách sinh viên cần xóa trống");
        blockStudents(ids);
        return ids.size();
    }

    private void blockStudents(List<Long> ids) {
        for (Long id : ids) {
            Student student = studentRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên với id: " + id));
            student.setStatus(StudentStatus.LOCKED);
            studentRepository.save(student);
        }
    }

    private Student buildStudentFromCreate(CreateStudentRequest req, User user) {
        Student student = new Student();
        student.setUser(user);
        student.setStudentCode(req.getStudentCode());
        student.setFullName(req.getFullName());
        student.setDateOfBirth(req.getDateOfBirth());
        student.setGender(req.getGender());
        student.setPhone(req.getPhone());
        student.setCccd(req.getCccd());
        student.setEthnicity(req.getEthnicity());
        student.setReligion(req.getReligion());
        student.setNationality(req.getNationality());
        student.setPlaceOfBirth(req.getPlaceOfBirth());
        student.setStartYear(req.getStartYear());
        student.setEndYear(req.getEndYear());
        student.setStatus(req.getStatus() != null ? parseStatus(req.getStatus()) : StudentStatus.ACTIVE);
        return student;
    }

    private void validateStudentFields(String fullName, LocalDate dateOfBirth,
                                        String gender, String phone,
                                        Integer startYear, Integer endYear) {
        int currentYear = LocalDate.now().getYear();

        if (!isBlank(fullName)) {
            if (!fullName.matches("^[\\p{L} ]+$"))
                throw new IllegalArgumentException("Họ tên không được chứa số hoặc ký tự đặc biệt");
        }

        if (dateOfBirth != null) {
            int age = currentYear - dateOfBirth.getYear();
            if (age < 17)
                throw new IllegalArgumentException("Ngày sinh không hợp lệ");
        }

        if (!isBlank(gender)) {
            if (!gender.equalsIgnoreCase("Nam") && !gender.equalsIgnoreCase("Nữ"))
                throw new IllegalArgumentException("Giới tính không hợp lệ ('Nam' hoặc 'Nữ')");
        }

        if (!isBlank(phone)) {
            if (!phone.matches("^0\\d{9,10}$"))
                throw new IllegalArgumentException("Số điện thoại phải gồm 10-11 số, bắt đầu bằng 0");
        }

        if (startYear != null && startYear > currentYear)
            throw new IllegalArgumentException("Năm nhập học không được lớn hơn " + currentYear);

        if (startYear != null && endYear != null && endYear - startYear < 4)
            throw new IllegalArgumentException("Năm kết thúc không hợp lệ");
    }

    private AdminStudentResponse toListResponse(Student s) {
        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_Id(s.getId());

        return AdminStudentResponse.builder()
                .id(s.getId())
                .studentCode(s.getStudentCode())
                .fullName(s.getFullName())
                .gender(s.getGender())
                .dateOfBirth(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DATE_FMT) : null)
                .phone(s.getPhone())
                .email(s.getUser() != null ? s.getUser().getEmail() : null)
                .status(statusLabel(s.getStatus()))
                .startYear(s.getStartYear())
                .className(spOpt.map(StudentProgram::getClassName).orElse(null))
                .faculty(spOpt.map(sp -> sp.getProgram().getFaculty()).orElse(null))
                .major(spOpt.map(sp -> sp.getProgram().getMajor()).orElse(null))
                .specialization(spOpt.map(sp -> sp.getProgram().getSpecialization()).orElse(null))
                .build();
    }

    private AdminStudentDetailResponse toDetailResponse(Student s) {
        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_Id(s.getId());

        return AdminStudentDetailResponse.builder()
                .id(s.getId())
                .studentCode(s.getStudentCode())
                .fullName(s.getFullName())
                .gender(s.getGender())
                .dateOfBirth(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DATE_FMT) : null)
                .phone(s.getPhone())
                .email(s.getUser() != null ? s.getUser().getEmail() : null)
                .status(statusLabel(s.getStatus()))
                .startYear(s.getStartYear())
                .endYear(s.getEndYear())
                .cccd(s.getCccd())
                .ethnicity(s.getEthnicity())
                .religion(s.getReligion())
                .nationality(s.getNationality())
                .placeOfBirth(s.getPlaceOfBirth())
                .programId(spOpt.map(sp -> sp.getProgram().getId()).orElse(null))
                .className(spOpt.map(StudentProgram::getClassName).orElse(null))
                .faculty(spOpt.map(sp -> sp.getProgram().getFaculty()).orElse(null))
                .major(spOpt.map(sp -> sp.getProgram().getMajor()).orElse(null))
                .specialization(spOpt.map(sp -> sp.getProgram().getSpecialization()).orElse(null))
                .educationType(spOpt.map(sp -> sp.getProgram().getEducationType()).orElse(null))
                .build();
    }

    private StudentStatus parseStatus(String raw) {
        if (isBlank(raw)) return StudentStatus.ACTIVE;
        try {
            return StudentStatus.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return switch (raw.trim().toLowerCase()) {
                case "đang học" -> StudentStatus.ACTIVE;
                case "đã tốt nghiệp" -> StudentStatus.GRADUATED;
                case "tạm khóa", "tạm nghỉ" -> StudentStatus.LOCKED;
                case "vô hiệu", "đã xóa" -> StudentStatus.LOCKED;
                default -> throw new IllegalArgumentException("Trạng thái không hợp lệ: " + raw);
            };
        }
    }

    private String statusLabel(StudentStatus status) {
        if (status == null) return StudentStatus.ACTIVE.name();
        return status.name();
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
