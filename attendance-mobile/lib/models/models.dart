class Branch {
  final int id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Clazz {
  final int id;
  final String name;

  Clazz({required this.id, required this.name});

  factory Clazz.fromJson(Map<String, dynamic> json) {
    return Clazz(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Batch {
  final int id;
  final String name;
  final int classId;
  final String className;

  Batch({
    required this.id,
    required this.name,
    required this.classId,
    required this.className,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    final clazz = json['clazz'] as Map<String, dynamic>?;
    return Batch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      classId: clazz != null ? (clazz['id'] ?? 0) : 0,
      className: clazz != null ? (clazz['name'] ?? '') : '',
    );
  }
}

class Subject {
  final int id;
  final String name;
  final int classId;
  final String className;

  Subject({
    required this.id,
    required this.name,
    required this.classId,
    required this.className,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final clazz = json['clazz'] as Map<String, dynamic>?;
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      classId: clazz != null ? (clazz['id'] ?? 0) : 0,
      className: clazz != null ? (clazz['name'] ?? '') : '',
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String name;
  final String email;
  final String role;
  final List<String> branches;

  UserProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.branches,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      branches: List<String>.from(json['branches'] ?? []),
    );
  }
}

class Student {
  final int id;
  final String studentId;
  final String name;
  final String rollNumber;
  final int classId;
  final String className;
  final int batchId;
  final String batchName;
  final String parentName;
  final String parentMobile;
  final String parentWhatsApp;
  final String address;
  final String photoUrl;
  final String qrCodeToken;

  Student({
    required this.id,
    required this.studentId,
    required this.name,
    required this.rollNumber,
    required this.classId,
    required this.className,
    required this.batchId,
    required this.batchName,
    required this.parentName,
    required this.parentMobile,
    required this.parentWhatsApp,
    required this.address,
    required this.photoUrl,
    required this.qrCodeToken,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final clazz = json['clazz'] as Map<String, dynamic>?;
    final batch = json['batch'] as Map<String, dynamic>?;
    return Student(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? '',
      name: json['name'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      classId: clazz != null ? (clazz['id'] ?? 0) : 0,
      className: clazz != null ? (clazz['name'] ?? '') : '',
      batchId: batch != null ? (batch['id'] ?? 0) : 0,
      batchName: batch != null ? (batch['name'] ?? '') : '',
      parentName: json['parentName'] ?? '',
      parentMobile: json['parentMobile'] ?? '',
      parentWhatsApp: json['parentWhatsApp'] ?? '',
      address: json['address'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      qrCodeToken: json['qrCodeToken'] ?? '',
    );
  }
}

class AttendanceRecord {
  final int id;
  final String studentIdStr;
  final String studentName;
  final String rollNumber;
  final String className;
  final String batchName;
  final String date;
  final String time;
  final String status; // PRESENT or ABSENT
  final String teacherName;

  AttendanceRecord({
    required this.id,
    required this.studentIdStr,
    required this.studentName,
    required this.rollNumber,
    required this.className,
    required this.batchName,
    required this.date,
    required this.time,
    required this.status,
    required this.teacherName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final batch = json['batch'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;

    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentIdStr: student != null ? (student['studentId'] ?? '') : '',
      studentName: student != null ? (student['name'] ?? '') : '',
      rollNumber: student != null ? (student['rollNumber'] ?? '') : '',
      className: (student != null && student['clazz'] != null) ? (student['clazz']['name'] ?? '') : '',
      batchName: batch != null ? (batch['name'] ?? '') : '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      teacherName: teacher != null ? (teacher['name'] ?? '') : '',
    );
  }
}

class AttendanceSession {
  final int id;
  final int batchId;
  final String batchName;
  final String className;
  final String teacherName;
  final String subjectName;
  final String date;
  final String submittedAt;

  AttendanceSession({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.className,
    required this.teacherName,
    required this.subjectName,
    required this.date,
    required this.submittedAt,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;
    final subject = json['subject'] as Map<String, dynamic>?;

    return AttendanceSession(
      id: json['id'] ?? 0,
      batchId: batch != null ? (batch['id'] ?? 0) : 0,
      batchName: batch != null ? (batch['name'] ?? '') : '',
      className: (batch != null && batch['clazz'] != null) ? (batch['clazz']['name'] ?? '') : '',
      teacherName: teacher != null ? (teacher['name'] ?? '') : '',
      subjectName: subject != null ? (subject['name'] ?? 'General') : 'General',
      date: json['date'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
    );
  }
}
