import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'register_student.dart';
import 'student_qr_viewer.dart';
import '../../services/api_service.dart';

class ManageStudents extends StatefulWidget {
  const ManageStudents({super.key});

  @override
  State<ManageStudents> createState() => _ManageStudentsState();
}

class _ManageStudentsState extends State<ManageStudents> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminProvider>(context, listen: false).loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filteredStudents = admin.students
        .where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.rollNumber.contains(_searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterStudent()),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Student ID or Roll No...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No students found.', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: filteredStudents.length,
                        itemBuilder: (ctx, idx) {
                          final student = filteredStudents[idx];
                          
                          // Resolve image path (handles relative uploads or full urls)
                          String fullPhotoUrl = student.photoUrl;
                          if (fullPhotoUrl.isNotEmpty && fullPhotoUrl.startsWith('/uploads/')) {
                            fullPhotoUrl = '${admin.settings['server_url'] ?? ApiService().baseUrl}$fullPhotoUrl';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GlassCard(
                              child: Row(
                                children: [
                                  // Student Photo Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: student.photoUrl.isEmpty
                                        ? Container(
                                            width: 60,
                                            height: 60,
                                            color: AppTheme.primary.withOpacity(0.1),
                                            child: const Icon(Icons.person, color: AppTheme.primary, size: 30),
                                          )
                                        : Image.network(
                                            fullPhotoUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              width: 60,
                                              height: 60,
                                              color: AppTheme.primary.withOpacity(0.1),
                                              child: const Icon(Icons.person, color: AppTheme.primary, size: 30),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Student Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${student.studentId}  |  Roll: ${student.rollNumber}',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${student.className} - ${student.batchName}',
                                          style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Quick Action Icons
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.qr_code_2, color: AppTheme.primary),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StudentQrViewer(student: student),
                                            ),
                                          );
                                        },
                                        tooltip: 'View QR Code',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RegisterStudent(studentToEdit: student),
                                            ),
                                          );
                                        },
                                        tooltip: 'Edit Profile',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (c) => AlertDialog(
                                              backgroundColor: AppTheme.surface,
                                              title: const Text('Confirm Delete', style: TextStyle(color: AppTheme.textPrimary)),
                                              content: Text('Are you sure you want to delete student "${student.name}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(c),
                                                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                  onPressed: () {
                                                    admin.deleteStudent(student.id);
                                                    Navigator.pop(c);
                                                  },
                                                  child: const Text('Delete'),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                        tooltip: 'Delete Student',
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
