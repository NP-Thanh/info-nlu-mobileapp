package com.example.nlu.service;

import com.example.nlu.dto.request.CreateStudentRequest;
import com.example.nlu.dto.request.UpdateStudentRequest;
import com.example.nlu.dto.response.AdminStudentResponse;
import com.example.nlu.entity.Role;
import com.example.nlu.entity.Student;
import com.example.nlu.entity.StudentProgram;
import com.example.nlu.entity.User;
import com.example.nlu.repo.StudentProgramRepository;
import com.example.nlu.repo.StudentRepository;
import com.example.nlu.repo.UserRepository;
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
    private final PasswordEncoder passwordEncoder;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public List<AdminStudentResponse> getStudents(String keyword,
                                                   String className,
                                                   String faculty,
                                                   Integer startYear) {
        List<Student> students = studentRepository.searchStudents(
                isBlank(keyword) ? null : keyword.trim(),
                startYear
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

        return students.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public AdminStudentResponse createStudent(CreateStudentRequest req) {
        // Validate required fields
        if (isBlank(req.getStudentCode()))
            throw new IllegalArgumentException("Mã sinh viên không được để trống");
        if (isBlank(req.getEmail()))
            throw new IllegalArgumentException("Email không được để trống");

        if (studentRepository.findByStudentCode(req.getStudentCode()).isPresent())
            throw new IllegalArgumentException("Mã sinh viên đã tồn tại: " + req.getStudentCode());
        if (userRepository.findByUsername(req.getStudentCode()).isPresent())
            throw new IllegalArgumentException("Tài khoản đã tồn tại: " + req.getStudentCode());

        // Validate student fields
        validateStudentFields(req.getFullName(), req.getDateOfBirth(), req.getGender(),
                req.getPhone(), req.getStartYear(), req.getEndYear());

        // Create user
        User user = new User();
        user.setUsername(req.getStudentCode());
        user.setPassword(passwordEncoder.encode(req.getStudentCode()));
        user.setEmail(req.getEmail());
        user.setRole(Role.STUDENT);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        userRepository.save(user);

        // Create student
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
        student.setStatus(req.getStatus());
        studentRepository.save(student);

        return toResponse(student);
    }

    @Transactional
    public AdminStudentResponse updateStudent(Long id, UpdateStudentRequest req) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên với id: " + id));

        validateStudentFields(req.getFullName(), req.getDateOfBirth(), req.getGender(),
                req.getPhone(), req.getStartYear(), req.getEndYear());

        if (!isBlank(req.getFullName()))       student.setFullName(req.getFullName());
        if (req.getDateOfBirth() != null)      student.setDateOfBirth(req.getDateOfBirth());
        if (!isBlank(req.getGender()))         student.setGender(req.getGender());
        if (!isBlank(req.getPhone()))          student.setPhone(req.getPhone());
        if (!isBlank(req.getCccd()))           student.setCccd(req.getCccd());
        if (!isBlank(req.getEthnicity()))      student.setEthnicity(req.getEthnicity());
        if (!isBlank(req.getReligion()))       student.setReligion(req.getReligion());
        if (!isBlank(req.getNationality()))    student.setNationality(req.getNationality());
        if (!isBlank(req.getPlaceOfBirth()))   student.setPlaceOfBirth(req.getPlaceOfBirth());
        if (req.getStartYear() != null)        student.setStartYear(req.getStartYear());
        if (req.getEndYear() != null)          student.setEndYear(req.getEndYear());
        if (!isBlank(req.getStatus()))         student.setStatus(req.getStatus());

        studentRepository.save(student);
        return toResponse(student);
    }

    @Transactional
    public void deleteStudent(Long id) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy sinh viên với id: " + id));

        User user = student.getUser();

        // Xóa student_programs
        List<StudentProgram> programs = studentProgramRepository.findAllByStudent_Id(id);
        studentProgramRepository.deleteAll(programs);

        studentRepository.delete(student);

        if (user != null) {
            userRepository.delete(user);
        }
    }

    private void validateStudentFields(String fullName, LocalDate dateOfBirth,
                                        String gender, String phone,
                                        Integer startYear, Integer endYear) {
        int currentYear = LocalDate.now().getYear();

        if (!isBlank(fullName)) {
            // Chỉ cho phép chữ cái và khoảng trắng
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
                throw new IllegalArgumentException("Giới tính không hợp lệ('Nam' hoặc 'Nữ')");
        }

        if (!isBlank(phone)) {
            if (!phone.matches("^0\\d{9,10}$"))
                throw new IllegalArgumentException("Số điện thoại phải gồm 10-11 số, bắt đầu bằng 0");
        }

        if (startYear != null) {
            if (startYear > currentYear)
                throw new IllegalArgumentException("Năm bắt đầu không được lớn hơn (" + currentYear + ")");
        }

        if (startYear != null && endYear != null) {
            if (endYear - startYear < 4)
                throw new IllegalArgumentException("Năm kết thúc không hợp lệ");
        }
    }

    private AdminStudentResponse toResponse(Student s) {
        Optional<StudentProgram> spOpt = studentProgramRepository.findFirstByStudent_Id(s.getId());

        return AdminStudentResponse.builder()
                .id(s.getId())
                .studentCode(s.getStudentCode())
                .fullName(s.getFullName())
                .gender(s.getGender())
                .dateOfBirth(s.getDateOfBirth() != null ? s.getDateOfBirth().format(DATE_FMT) : null)
                .phone(s.getPhone())
                .email(s.getUser() != null ? s.getUser().getEmail() : null)
                .status(s.getStatus())
                .startYear(s.getStartYear())
                .className(spOpt.map(StudentProgram::getClassName).orElse(null))
                .faculty(spOpt.map(sp -> sp.getProgram().getFaculty()).orElse(null))
                .major(spOpt.map(sp -> sp.getProgram().getMajor()).orElse(null))
                .specialization(spOpt.map(sp -> sp.getProgram().getSpecialization()).orElse(null))
                .build();
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
