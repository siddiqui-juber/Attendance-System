import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  String _error = '';

  List<Branch> _branches = [];
  List<Clazz> _classes = [];
  List<Batch> _batches = [];
  List<Subject> _subjects = [];
  List<UserProfile> _teachers = [];
  List<Student> _students = [];
  Map<String, String> _settings = {};
  Map<String, dynamic> _stats = {};

  bool get isLoading => _isLoading;
  String get error => _error;
  List<Branch> get branches => _branches;
  List<Clazz> get classes => _classes;
  List<Batch> get batches => _batches;
  List<Subject> get subjects => _subjects;
  List<UserProfile> get teachers => _teachers;
  List<Student> get students => _students;
  Map<String, String> get settings => _settings;
  Map<String, dynamic> get stats => _stats;

  void clearError() {
    _error = '';
    notifyListeners();
  }

  // --- Utility Loader ---
  Future<void> loadMetadata() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        loadBranches(),
        loadClasses(),
        loadBatches(),
        loadSubjects()
      ]);
    } catch (e) {
      _error = 'Failed to load metadata';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Branches ---
  Future<void> loadBranches() async {
    final response = await _api.get('/api/admin/branches');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _branches = data.map((e) => Branch.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<bool> createBranch(String name) async {
    final response = await _api.post('/api/admin/branches', {'name': name});
    if (response.statusCode == 200) {
      await loadBranches();
      return true;
    }
    return false;
  }

  Future<void> deleteBranch(int id) async {
    final response = await _api.delete('/api/admin/branches/$id');
    if (response.statusCode == 200) {
      _branches.removeWhere((b) => b.id == id);
      notifyListeners();
    }
  }

  // --- Classes ---
  Future<void> loadClasses() async {
    final response = await _api.get('/api/admin/classes');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _classes = data.map((e) => Clazz.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<bool> createClass(String name) async {
    final response = await _api.post('/api/admin/classes', {'name': name});
    if (response.statusCode == 200) {
      await loadClasses();
      return true;
    }
    return false;
  }

  Future<void> deleteClass(int id) async {
    final response = await _api.delete('/api/admin/classes/$id');
    if (response.statusCode == 200) {
      _classes.removeWhere((c) => c.id == id);
      notifyListeners();
    }
  }

  // --- Batches ---
  Future<void> loadBatches() async {
    final response = await _api.get('/api/admin/batches');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _batches = data.map((e) => Batch.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<bool> createBatch(String name, int classId) async {
    final response = await _api.post('/api/admin/batches', {
      'name': name,
      'clazz': {'id': classId}
    });
    if (response.statusCode == 200) {
      await loadBatches();
      return true;
    }
    return false;
  }

  Future<void> deleteBatch(int id) async {
    final response = await _api.delete('/api/admin/batches/$id');
    if (response.statusCode == 200) {
      _batches.removeWhere((b) => b.id == id);
      notifyListeners();
    }
  }

  // --- Subjects ---
  Future<void> loadSubjects() async {
    final response = await _api.get('/api/admin/subjects');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      _subjects = data.map((e) => Subject.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<bool> createSubject(String name, int classId) async {
    final response = await _api.post('/api/admin/subjects', {
      'name': name,
      'clazz': {'id': classId}
    });
    if (response.statusCode == 200) {
      await loadSubjects();
      return true;
    }
    return false;
  }

  Future<void> deleteSubject(int id) async {
    final response = await _api.delete('/api/admin/subjects/$id');
    if (response.statusCode == 200) {
      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }

  // --- Teachers ---
  Future<void> loadTeachers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/admin/teachers');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _teachers = data.map((e) => UserProfile.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load teachers';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerTeacher(String name, String username, String email, String password, List<int> branchIds) async {
    final response = await _api.post('/api/admin/teachers', {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'branchIds': branchIds
    });
    if (response.statusCode == 200) {
      await loadTeachers();
      return true;
    }
    return false;
  }

  Future<bool> updateTeacher(int id, String name, String email, String password, List<int> branchIds) async {
    final response = await _api.put('/api/admin/teachers/$id', {
      'name': name,
      'email': email,
      'password': password,
      'branchIds': branchIds
    });
    if (response.statusCode == 200) {
      await loadTeachers();
      return true;
    }
    return false;
  }

  Future<void> deleteTeacher(int id) async {
    final response = await _api.delete('/api/admin/teachers/$id');
    if (response.statusCode == 200) {
      _teachers.removeWhere((t) => t.id == id);
      notifyListeners();
    }
  }

  // --- Students ---
  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/admin/students');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _students = data.map((e) => Student.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load students';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Student?> registerStudent({
    required String name,
    required String rollNumber,
    required int classId,
    required int batchId,
    required String parentName,
    required String parentMobile,
    required String parentWhatsApp,
    required String address,
    required String photoUrl,
    String studentId = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.post('/api/admin/students', {
        'studentId': studentId,
        'name': name,
        'rollNumber': rollNumber,
        'classId': classId,
        'batchId': batchId,
        'parentName': parentName,
        'parentMobile': parentMobile,
        'parentWhatsApp': parentWhatsApp,
        'address': address,
        'photoUrl': photoUrl,
      });

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final student = Student.fromJson(data);
        await loadStudents();
        return student;
      }
    } catch (e) {
      _error = 'Student registration failed';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> updateStudent(int id, {
    required String name,
    required String rollNumber,
    required int classId,
    required int batchId,
    required String parentName,
    required String parentMobile,
    required String parentWhatsApp,
    required String address,
    required String photoUrl,
  }) async {
    final response = await _api.put('/api/admin/students/$id', {
      'name': name,
      'rollNumber': rollNumber,
      'classId': classId,
      'batchId': batchId,
      'parentName': parentName,
      'parentMobile': parentMobile,
      'parentWhatsApp': parentWhatsApp,
      'address': address,
      'photoUrl': photoUrl,
    });

    if (response.statusCode == 200) {
      await loadStudents();
      return true;
    }
    return false;
  }

  Future<void> deleteStudent(int id) async {
    final response = await _api.delete('/api/admin/students/$id');
    if (response.statusCode == 200) {
      _students.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }

  Future<Student?> regenerateQrCode(int id) async {
    final response = await _api.post('/api/admin/students/$id/regenerate-qr', {});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final updated = Student.fromJson(data);
      await loadStudents();
      return updated;
    }
    return null;
  }

  // --- Settings ---
  Future<void> loadSettings() async {
    final response = await _api.get('/api/admin/settings');
    if (response.statusCode == 200) {
      _settings = Map<String, String>.from(jsonDecode(response.body));
      notifyListeners();
    }
  }

  Future<void> updateSetting(String key, String value) async {
    final response = await _api.post('/api/admin/settings?key=$key&value=$value', {});
    if (response.statusCode == 200) {
      _settings[key] = value;
      notifyListeners();
    }
  }

  // --- Dashboard Stats ---
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/admin/dashboard/stats');
      if (response.statusCode == 200) {
        _stats = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load stats';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
