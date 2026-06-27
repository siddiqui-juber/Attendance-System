package com.Genxcraft.Backend.service;

import com.Genxcraft.Backend.dto.DashboardStatsResponse;
import com.Genxcraft.Backend.dto.StudentRegisterRequest;
import com.Genxcraft.Backend.dto.TeacherRegisterRequest;
import com.Genxcraft.Backend.entity.*;
import com.Genxcraft.Backend.repository.*;
import com.Genxcraft.Backend.util.EncryptionUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminService {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private BranchRepository branchRepository;
    @Autowired
    private ClazzRepository clazzRepository;
    @Autowired
    private BatchRepository batchRepository;
    @Autowired
    private SubjectRepository subjectRepository;
    @Autowired
    private StudentRepository studentRepository;
    @Autowired
    private AttendanceRepository attendanceRepository;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private EncryptionUtils encryptionUtils;

    // --- Branch CRUD ---
    public Branch createBranch(Branch branch) {
        return branchRepository.save(branch);
    }

    public List<Branch> getAllBranches() {
        return branchRepository.findAll();
    }

    public void deleteBranch(Long id) {
        branchRepository.deleteById(id);
    }

    // --- Class CRUD ---
    public Clazz createClass(Clazz clazz) {
        return clazzRepository.save(clazz);
    }

    public List<Clazz> getAllClasses() {
        return clazzRepository.findAll();
    }

    public void deleteClass(Long id) {
        clazzRepository.deleteById(id);
    }

    // --- Batch CRUD ---
    public Batch createBatch(Batch batch) {
        return batchRepository.save(batch);
    }

    public List<Batch> getAllBatches() {
        return batchRepository.findAll();
    }

    public List<Batch> getBatchesByClass(Long classId) {
        return batchRepository.findByClazzId(classId);
    }

    public void deleteBatch(Long id) {
        batchRepository.deleteById(id);
    }

    // --- Subject CRUD ---
    public Subject createSubject(Subject subject) {
        return subjectRepository.save(subject);
    }

    public List<Subject> getAllSubjects() {
        return subjectRepository.findAll();
    }

    public List<Subject> getSubjectsByClass(Long classId) {
        return subjectRepository.findByClazzId(classId);
    }

    public void deleteSubject(Long id) {
        subjectRepository.deleteById(id);
    }

    // --- Teacher CRUD ---
    public User registerTeacher(TeacherRegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists");
        }

        Set<Branch> assignedBranches = new HashSet<>();
        if (request.getBranchIds() != null) {
            assignedBranches.addAll(branchRepository.findAllById(request.getBranchIds()));
        }

        User teacher = User.builder()
                .name(request.getName())
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(Role.TEACHER)
                .branches(assignedBranches)
                .active(true)
                .build();

        return userRepository.save(teacher);
    }

    public List<User> getAllTeachers() {
        return userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.TEACHER)
                .collect(Collectors.toList());
    }

    public User updateTeacher(Long id, TeacherRegisterRequest request) {
        User teacher = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Teacher not found"));

        teacher.setName(request.getName());
        teacher.setEmail(request.getEmail());
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            teacher.setPassword(passwordEncoder.encode(request.getPassword()));
        }

        Set<Branch> assignedBranches = new HashSet<>();
        if (request.getBranchIds() != null) {
            assignedBranches.addAll(branchRepository.findAllById(request.getBranchIds()));
        }
        teacher.setBranches(assignedBranches);

        return userRepository.save(teacher);
    }

    public void deleteTeacher(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Teacher not found"));
        userRepository.delete(user);
    }

    // --- Student CRUD ---
    @Transactional
    public Student registerStudent(StudentRegisterRequest request) {
        Clazz clazz = clazzRepository.findById(request.getClassId())
                .orElseThrow(() -> new RuntimeException("Class not found"));

        Batch batch = batchRepository.findById(request.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch not found"));

        String studentId = request.getStudentId();
        if (studentId == null || studentId.trim().isEmpty()) {
            long count = studentRepository.count();
            studentId = "STU" + String.format("%04d", count + 1);
        } else if (studentRepository.existsByStudentId(studentId)) {
            throw new RuntimeException("Student ID already exists");
        }

        // Generate encrypted student identifier
        String qrToken = encryptionUtils.encrypt(studentId);

        Student student = Student.builder()
                .studentId(studentId)
                .name(request.getName())
                .rollNumber(request.getRollNumber())
                .clazz(clazz)
                .batch(batch)
                .parentName(request.getParentName())
                .parentMobile(request.getParentMobile())
                .parentWhatsApp(request.getParentWhatsApp())
                .address(request.getAddress())
                .photoUrl(request.getPhotoUrl())
                .qrCodeToken(qrToken)
                .build();

        return studentRepository.save(student);
    }

    public Student updateStudent(Long id, StudentRegisterRequest request) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        Clazz clazz = clazzRepository.findById(request.getClassId())
                .orElseThrow(() -> new RuntimeException("Class not found"));

        Batch batch = batchRepository.findById(request.getBatchId())
                .orElseThrow(() -> new RuntimeException("Batch not found"));

        student.setName(request.getName());
        student.setRollNumber(request.getRollNumber());
        student.setClazz(clazz);
        student.setBatch(batch);
        student.setParentName(request.getParentName());
        student.setParentMobile(request.getParentMobile());
        student.setParentWhatsApp(request.getParentWhatsApp());
        student.setAddress(request.getAddress());
        if (request.getPhotoUrl() != null && !request.getPhotoUrl().isEmpty()) {
            student.setPhotoUrl(request.getPhotoUrl());
        }

        return studentRepository.save(student);
    }

    public List<Student> getAllStudents() {
        return studentRepository.findAll();
    }

    public Student getStudent(Long id) {
        return studentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student not found"));
    }

    public void deleteStudent(Long id) {
        studentRepository.deleteById(id);
    }

    public Student regenerateQrCode(Long id) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        // Generate a new QR token by encrypting the student ID again (or adding UUID salt if needed,
        // but simple encryption is sufficient here)
        String newQrToken = encryptionUtils.encrypt(student.getStudentId() + "_" + UUID.randomUUID().toString().substring(0, 4));
        student.setQrCodeToken(newQrToken);
        return studentRepository.save(student);
    }

    // --- Dashboard Analytics ---
    public DashboardStatsResponse getDashboardStats() {
        long totalStudents = studentRepository.count();
        long totalTeachers = userRepository.findAll().stream().filter(u -> u.getRole() == Role.TEACHER).count();
        long totalBranches = branchRepository.count();
        long totalBatches = batchRepository.count();

        LocalDate today = LocalDate.now();
        long todayPresent = attendanceRepository.countByDateAndStatus(today, AttendanceStatus.PRESENT);
        long todayAbsent = attendanceRepository.countByDateAndStatus(today, AttendanceStatus.ABSENT);
        long totalMarked = todayPresent + todayAbsent;
        double todayPercentage = totalMarked == 0 ? 0.0 : (double) todayPresent / totalMarked * 100.0;

        // Generate weekly graphs data
        Map<String, Long> weeklyPresent = new LinkedHashMap<>();
        Map<String, Long> weeklyAbsent = new LinkedHashMap<>();
        
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            String dateStr = date.getDayOfWeek().name().substring(0, 3); // e.g. MON, TUE
            weeklyPresent.put(dateStr, attendanceRepository.countByDateAndStatus(date, AttendanceStatus.PRESENT));
            weeklyAbsent.put(dateStr, attendanceRepository.countByDateAndStatus(date, AttendanceStatus.ABSENT));
        }

        return DashboardStatsResponse.builder()
                .totalStudents(totalStudents)
                .totalTeachers(totalTeachers)
                .totalBranches(totalBranches)
                .totalBatches(totalBatches)
                .todayPresentCount(todayPresent)
                .todayAbsentCount(todayAbsent)
                .todayAttendancePercentage(todayPercentage)
                .weeklyPresentStats(weeklyPresent)
                .weeklyAbsentStats(weeklyAbsent)
                .build();
    }
}
