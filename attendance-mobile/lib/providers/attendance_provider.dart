import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String _error = '';

  // Setup Details
  Batch? _activeBatch;
  Subject? _activeSubject;
  DateTime _activeDate = DateTime.now();

  // Active Session Lists
  List<Student> _batchStudents = []; // All students in this batch
  final List<Student> _presentStudents = []; // Students scanned/marked present
  final List<String> _duplicateScanTokens = []; // Track already scanned tokens in this session

  // History List
  List<AttendanceSession> _sessions = [];
  List<AttendanceRecord> _activeSessionRecords = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  Batch? get activeBatch => _activeBatch;
  Subject? get activeSubject => _activeSubject;
  DateTime get activeDate => _activeDate;
  
  List<Student> get batchStudents => _batchStudents;
  List<Student> get presentStudents => _presentStudents;
  List<AttendanceSession> get sessions => _sessions;
  List<AttendanceRecord> get activeSessionRecords => _activeSessionRecords;

  // List of absent students in current active session
  List<Student> get absentStudents {
    final presentIds = _presentStudents.map((e) => e.id).toSet();
    return _batchStudents.where((s) => !presentIds.contains(s.id)).toList();
  }

  void startSession(Batch batch, Subject? subject, DateTime date) {
    _activeBatch = batch;
    _activeSubject = subject;
    _activeDate = date;
    _presentStudents.clear();
    _duplicateScanTokens.clear();
    _batchStudents.clear();
    _error = '';
    notifyListeners();
    loadBatchStudents(batch.id);
  }

  Future<void> loadBatchStudents(int batchId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/admin/students'); // Or filter by batch on backend
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final all = data.map((e) => Student.fromJson(e)).toList();
        _batchStudents = all.where((s) => s.batchId == batchId).toList();
      }
    } catch (e) {
      _error = 'Failed to load student batch list';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify and scan a QR Code
  Future<Map<String, dynamic>> scanQrCode(String token) async {
    if (_activeBatch == null) {
      return {'success': false, 'message': 'No active session batch selected'};
    }

    // 1. Duplicate check in active local session memory
    if (_duplicateScanTokens.contains(token)) {
      final student = _presentStudents.firstWhere((s) => s.qrCodeToken == token);
      return {
        'success': false,
        'message': 'Duplicate Scan: ${student.name} is already marked Present',
        'isDuplicate': true,
        'student': student
      };
    }

    try {
      final response = await _api.post(
        '/api/teacher/attendance/verify-qr?token=${Uri.encodeComponent(token)}&batchId=${_activeBatch!.id}',
        {}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool success = data['success'] ?? false;
        final String message = data['message'] ?? '';

        if (success) {
          final int studentId = data['id'];
          // Find student in local batch list
          final student = _batchStudents.firstWhere((s) => s.id == studentId);
          
          _presentStudents.add(student);
          _duplicateScanTokens.add(token);
          notifyListeners();

          return {
            'success': true,
            'message': message,
            'student': student
          };
        } else {
          // If backend says already present in DB
          if (data['currentStatus'] == 'PRESENT') {
            final int studentId = data['id'];
            final student = _batchStudents.firstWhere((s) => s.id == studentId);
            if (!_presentStudents.any((s) => s.id == studentId)) {
              _presentStudents.add(student);
              _duplicateScanTokens.add(token);
              notifyListeners();
            }
            return {
              'success': false,
              'message': 'This student\'s attendance has already been recorded.',
              'isDuplicate': true,
              'student': student
            };
          }
          return {'success': false, 'message': message};
        }
      } else {
        return {'success': false, 'message': 'Verification request failed (server error)'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error during verification'};
    }
  }

  // Toggle present/absent state manually (Teacher Override)
  void toggleStudentStatus(Student student) {
    if (_presentStudents.any((s) => s.id == student.id)) {
      _presentStudents.removeWhere((s) => s.id == student.id);
      _duplicateScanTokens.remove(student.qrCodeToken);
    } else {
      _presentStudents.add(student);
      _duplicateScanTokens.add(student.qrCodeToken);
    }
    notifyListeners();
  }

  // Submit session
  Future<bool> submitSession(int teacherId, String deviceInfo) async {
    if (_activeBatch == null) return false;

    _isLoading = true;
    notifyListeners();

    final dateStr = '${_activeDate.year}-${_activeDate.month.toString().padLeft(2, '0')}-${_activeDate.day.toString().padLeft(2, '0')}';
    final timeNow = TimeOfDay.fromDateTime(DateTime.now());
    final timeStr = '${timeNow.hour.toString().padLeft(2, '0')}:${timeNow.minute.toString().padLeft(2, '0')}';

    final body = {
      'batchId': _activeBatch!.id,
      'teacherId': teacherId,
      'subjectId': _activeSubject?.id,
      'date': dateStr,
      'time': timeStr,
      'presentStudentIds': _presentStudents.map((e) => e.id).toList(),
      'deviceInfo': deviceInfo,
    };

    try {
      final response = await _api.post('/api/teacher/attendance/submit', body);
      _isLoading = false;
      if (response.statusCode == 200) {
        // Clear session after successful submission
        _presentStudents.clear();
        _duplicateScanTokens.clear();
        _activeBatch = null;
        _activeSubject = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Failed to submit attendance';
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // History & Edits
  Future<void> loadTeacherHistory(int teacherId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/teacher/attendance/history?teacherId=$teacherId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _sessions = data.map((e) => AttendanceSession.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load attendance history';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionRecords(int batchId, String date) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.get('/api/teacher/attendance/session-details?batchId=$batchId&date=$date');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _activeSessionRecords = data.map((e) => AttendanceRecord.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load session details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editAttendanceRecord(int recordId, String status, String comment) async {
    try {
      final response = await _api.put(
        '/api/teacher/attendance/$recordId?status=$status&comment=${Uri.encodeComponent(comment)}',
        {}
      );
      if (response.statusCode == 200) {
        // Reload details
        final idx = _activeSessionRecords.indexWhere((r) => r.id == recordId);
        if (idx != -1) {
          final old = _activeSessionRecords[idx];
          _activeSessionRecords[idx] = AttendanceRecord(
            id: old.id,
            studentIdStr: old.studentIdStr,
            studentName: old.studentName,
            rollNumber: old.rollNumber,
            className: old.className,
            batchName: old.batchName,
            date: old.date,
            time: old.time,
            status: status,
            teacherName: old.teacherName,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      // Error editing
    }
    return false;
  }
}
