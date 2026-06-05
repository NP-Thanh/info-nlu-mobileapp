package com.example.nlu.repo;

import com.example.nlu.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    List<Enrollment> findAllBySection_Id(Long sectionId);

    List<Enrollment> findAllByStudent_Id(Long studentId);

    Optional<Enrollment> findByStudent_IdAndSection_Id(Long studentId, Long sectionId);

    boolean existsByStudent_IdAndSection_Id(Long studentId, Long sectionId);

    /** Lấy tất cả Enrollment của một student kèm section và course */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN FETCH e.section s
           JOIN FETCH s.course c
           WHERE e.student.studentCode = :studentCode
           """)
    List<Enrollment> findAllByStudentCode(@Param("studentCode") String studentCode);

    /** Lấy Enrollment theo student + semester + year */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN FETCH e.section s
           JOIN FETCH s.course c
           WHERE e.student.studentCode = :studentCode
             AND s.academicYear = :academicYear
             AND s.semester = :semester
           """)
    List<Enrollment> findByStudentAndSemester(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester);

    /** Các học kỳ phân biệt của một sinh viên */
    @Query("""
           SELECT DISTINCT s.semester, s.academicYear
           FROM Enrollment e
           JOIN e.section s
           WHERE e.student.studentCode = :studentCode
           ORDER BY s.academicYear DESC, s.semester DESC
           """)
    List<Object[]> findDistinctSemestersByStudent(@Param("studentCode") String studentCode);

    /** Tìm kiếm môn học trong một học kỳ cho một sinh viên */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN FETCH e.section s
           JOIN FETCH s.course c
           WHERE e.student.studentCode = :studentCode
             AND s.academicYear = :academicYear
             AND s.semester = :semester
             AND (:keyword IS NULL
                  OR LOWER(c.courseCode) LIKE LOWER(CONCAT('%', :keyword, '%'))
                  OR LOWER(c.courseName) LIKE LOWER(CONCAT('%', :keyword, '%')))
           ORDER BY c.courseCode
           """)
    List<Enrollment> findCoursesByStudentAndTerm(
            @Param("studentCode") String studentCode,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester,
            @Param("keyword") String keyword);

    /** Lấy các học kỳ phân biệt của student (dùng cho grade admin) */
    @Query("""
           SELECT DISTINCT s.semester, s.academicYear
           FROM Enrollment e
           JOIN e.section s
           WHERE e.student.studentCode = :studentCode
           ORDER BY s.academicYear DESC, s.semester DESC
           """)
    List<Object[]> findTermsByStudentCode(@Param("studentCode") String studentCode);

    /** Tìm enrollment LT (isLab=false) mới nhất theo student + course + semester + year */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN e.section s
           WHERE e.student.id = :studentId
             AND s.course.id = :courseId
             AND s.academicYear = :academicYear
             AND s.semester = :semester
             AND s.isLab = false
           ORDER BY e.id DESC
           """)
    List<Enrollment> findByStudentCourseTermNotLab(
            @Param("studentId") Long studentId,
            @Param("courseId") Long courseId,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester);

    /** Tìm enrollment LT mới nhất theo student + course */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN e.section s
           WHERE e.student.id = :studentId
             AND s.course.id = :courseId
             AND s.isLab = false
           ORDER BY e.id DESC
           """)
    List<Enrollment> findByStudentCourseNotLab(
            @Param("studentId") Long studentId,
            @Param("courseId") Long courseId);

    /** Tìm enrollment LT theo student + course + year + semester (dùng trong upsertGrade) */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN e.section s
           WHERE e.student.id = :studentId
             AND s.course.id = :courseId
             AND s.academicYear = :academicYear
             AND s.semester = :semester
             AND s.isLab = false
           ORDER BY e.id DESC
           """)
    Optional<Enrollment> findTopByStudent_IdAndCourse_IdAndAcademicYearAndSemesterAndIsLabFalseOrderByIdDesc(
            @Param("studentId") Long studentId,
            @Param("courseId") Long courseId,
            @Param("academicYear") String academicYear,
            @Param("semester") String semester);

    /** Tìm enrollment LT mới nhất theo student + course (không cần term) */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN e.section s
           WHERE e.student.id = :studentId
             AND s.course.id = :courseId
             AND s.isLab = false
           ORDER BY e.id DESC
           """)
    Optional<Enrollment> findTopByStudent_IdAndCourse_IdAndIsLabFalseOrderByIdDesc(
            @Param("studentId") Long studentId,
            @Param("courseId") Long courseId);

    /** Đếm số sinh viên trong một section */
    long countBySection_Id(Long sectionId);

    /** Lấy danh sách Enrollment cho một section kèm student info */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN FETCH e.student s
           WHERE e.section.id = :sectionId
           ORDER BY s.fullName ASC
           """)
    List<Enrollment> findBySectionIdWithStudent(@Param("sectionId") Long sectionId);

    /** Kiểm tra conflict lịch học của sinh viên */
    @Query("""
           SELECT e FROM Enrollment e
           JOIN e.section sec
           WHERE e.student.id = :studentId
             AND sec.semester = :semester
             AND sec.academicYear = :academicYear
             AND sec.id <> :excludeSectionId
             AND EXISTS (
               SELECT sch FROM Schedule sch
               WHERE sch.section.id = sec.id
                 AND sch.dayOfWeek = :dayOfWeek
                 AND sch.period = :period
                 AND (sch.isDeleted = false OR sch.isDeleted IS NULL)
             )
           """)
    List<Enrollment> findStudentConflicts(
            @Param("studentId") Long studentId,
            @Param("semester") String semester,
            @Param("academicYear") String academicYear,
            @Param("dayOfWeek") int dayOfWeek,
            @Param("period") int period,
            @Param("excludeSectionId") Long excludeSectionId);
}
