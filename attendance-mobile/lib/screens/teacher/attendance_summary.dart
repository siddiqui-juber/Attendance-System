import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AttendanceSummary extends StatefulWidget {
  const AttendanceSummary({super.key});

  @override
  State<AttendanceSummary> createState() => _AttendanceSummaryState();
}

class _AttendanceSummaryState extends State<AttendanceSummary> {
  bool _isSubmitting = false;

  void _handleSubmit() async {
    final att = Provider.of<AttendanceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isSubmitting = true;
    });

    final success = await att.submitSession(
      auth.userProfile?.id ?? 0,
      'Mobile App Scanner (iOS/Android)',
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance recorded & parent notifications queued!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(att.error.isNotEmpty ? att.error : 'Submission failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = Provider.of<AttendanceProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Session'),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Present (${att.presentStudents.length})'),
              Tab(text: 'Absent (${att.absentStudents.length})'),
            ],
          ),
        ),
        body: _isSubmitting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting session & sending notifications...', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Present Students
                        _buildStudentList(att.presentStudents, isPresent: true, onToggle: (s) => att.toggleStudentStatus(s)),
                        // Tab 2: Absent Students
                        _buildStudentList(att.absentStudents, isPresent: false, onToggle: (s) => att.toggleStudentStatus(s)),
                      ],
                    ),
                  ),
                  
                  // Submit Panel
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Students in Batch:', style: TextStyle(color: AppTheme.textSecondary)),
                              Text(
                                '${att.batchStudents.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleSubmit,
                          child: const Text('Submit Attendance'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStudentList(List<dynamic> list, {required bool isPresent, required Function(dynamic) onToggle}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPresent ? Icons.people_outline : Icons.check_circle_outline,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isPresent ? 'No students scanned yet.' : 'All students present!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final student = list[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                  child: Icon(
                    isPresent ? Icons.check : Icons.close,
                    color: isPresent ? Colors.green : Colors.redAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Roll No: ${student.rollNumber}  |  ID: ${student.studentId}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Toggle Button for manual override
                IconButton(
                  icon: Icon(
                    isPresent ? Icons.remove_circle_outline : Icons.add_circle_outline,
                    color: isPresent ? Colors.redAccent : AppTheme.secondary,
                  ),
                  onPressed: () => onToggle(student),
                  tooltip: isPresent ? 'Mark Absent' : 'Mark Present',
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
