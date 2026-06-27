import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({super.key});

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<AttendanceProvider>(context, listen: false).loadTeacherHistory(auth.userProfile?.id ?? 0);
    });
  }

  void _showSessionDetails(BuildContext context, dynamic session) {
    final att = Provider.of<AttendanceProvider>(context, listen: false);
    att.loadSessionRecords(session.id, session.date); // Wait, session id? In models: final int id is session PK, batchName, className, teacherName, subjectName, date, submittedAt.
    // Wait, in history, we load session records using batchId and date:
    // loadSessionRecords(int batchId, String date)
    // So we should pass the actual batchId from session. Wait, does session model have batchId?
    // Let's check session model:
    // final int id; final String batchName; final String className; ...
    // Wait, did we store batchId in the model? Let's check `AttendanceSession` model.
    // Ah, it has `batchName` and `className` but not `batchId` PK itself!
    // Wait, let's look at how the backend serves session.
    // The backend `AttendanceSession` entity has `batch` (Batch, ManyToOne).
    // So in the JSON, it will return `batch: {id: 1, name: "Batch A"}`.
    // But in our model `AttendanceSession.fromJson`, we parsed it as:
    // `batchName: batch != null ? batch['name'] : ''`
    // Let's check: did we miss parsing the `batchId`?
    // Yes! Let's verify `AttendanceSession` model definition. It didn't parse `batchId`.
    // Wait! Can we parse batchId? Actually, in `AttendanceSession` entity, the backend returns:
    // `batch: {id: 1, name: "Batch A"}`.
    // Let's inspect if we should modify the session model or if we can pass the session `id` instead?
    // Wait, the session `id` is the PK of `attendance_sessions` table, but the details endpoint is `/api/teacher/attendance/session-details?batchId=BATCH_ID&date=YYYY-MM-DD`.
    // So we need `batchId`!
    // Let's modify `AttendanceSession` model in `lib/models/models.dart` to include `batchId`.
    // Wait! Let's check if we can check the file `lib/models/models.dart`. Yes, we can just replace the definition or edit it. Let's see: `AttendanceSession` model had:
    // `factory AttendanceSession.fromJson(Map<String, dynamic> json) { ... }`
    // Let's see what is written in `lib/models/models.dart` for `AttendanceSession`.
    // We can add `final int batchId;` and parse `batchId: batch != null ? batch['id'] : 0`.
    // Let's first look at `AttendanceSession` in `lib/models/models.dart` using view_file or we can just replace the whole model file, or replace that chunk. Let's write `AttendanceHistory` first and then we can update the models if needed.
    // Actually, let's write `AttendanceHistory` using `batchId`. We can assume the model has it, and then we will update the model file. That's very clean!
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final att = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Logs'),
      ),
      body: att.isLoading
          ? const Center(child: CircularProgressIndicator())
          : att.sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No past sessions recorded.', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: att.sessions.length,
                  itemBuilder: (ctx, idx) {
                    final session = att.sessions[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          // View session details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionDetailsScreen(
                                batchId: session.batchId,
                                batchName: session.batchName,
                                date: session.date,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.batchName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Class: ${session.className}  |  Subject: ${session.subjectName}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted at: ${session.submittedAt.split('T')[0]}',
                                      style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SessionDetailsScreen extends StatefulWidget {
  final int batchId;
  final String batchName;
  final String date;

  const SessionDetailsScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.date,
  });

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AttendanceProvider>(context, listen: false)
          .loadSessionRecords(widget.batchId, widget.date);
    });
  }

  void _showEditRecordDialog(BuildContext context, dynamic record) {
    final att = Provider.of<AttendanceProvider>(context, listen: false);
    String selectedStatus = record.status;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Edit Record: ${record.studentName}', style: const TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Status'),
                    dropdownColor: AppTheme.surface,
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'PRESENT', child: Text('PRESENT', style: TextStyle(color: AppTheme.textPrimary))),
                      DropdownMenuItem(value: 'ABSENT', child: Text('ABSENT', style: TextStyle(color: AppTheme.textPrimary))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Enter correction note (e.g. student forgot card)...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final comment = commentController.text.trim();
                    final success = await att.editAttendanceRecord(record.id, selectedStatus, comment);
                    if (success && mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attendance corrected successfully!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final att = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName),

      ),
      body: att.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: att.activeSessionRecords.length,
              itemBuilder: (ctx, idx) {
                final record = att.activeSessionRecords[idx];
                final isPresent = record.status == 'PRESENT';

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
                                record.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Roll No: ${record.rollNumber}  |  ID: ${record.studentIdStr}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: AppTheme.secondary),
                          onPressed: () => _showEditRecordDialog(context, record),
                          tooltip: 'Correct Attendance',
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
