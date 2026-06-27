import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'attendance_scanner.dart';

class AttendanceSetup extends StatefulWidget {
  const AttendanceSetup({super.key});

  @override
  State<AttendanceSetup> createState() => _AttendanceSetupState();
}

class _AttendanceSetupState extends State<AttendanceSetup> {
  int? _selectedBranchId;
  int? _selectedClassId;
  int? _selectedBatchId;
  int? _selectedSubjectId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadMetadata();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleStartSession() {
    if (_selectedBranchId == null || _selectedClassId == null || _selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Branch, Class, and Batch')),
      );
      return;
    }

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final att = Provider.of<AttendanceProvider>(context, listen: false);

    final batch = admin.batches.firstWhere((b) => b.id == _selectedBatchId);
    final subject = _selectedSubjectId != null 
        ? admin.subjects.firstWhere((s) => s.id == _selectedSubjectId) 
        : null;

    att.startSession(batch, subject, _selectedDate);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceScanner()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filteredBatches = admin.batches.where((b) => b.classId == _selectedClassId).toList();
    final filteredSubjects = admin.subjects.where((s) => s.classId == _selectedClassId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Setup'),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Configure Session details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    child: Column(
                      children: [
                        // Branch Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                            prefixIcon: Icon(Icons.storefront),
                          ),
                          dropdownColor: AppTheme.surface,
                          value: _selectedBranchId,
                          items: admin.branches
                              .map((b) => DropdownMenuItem<int>(
                                    value: b.id,
                                    child: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBranchId = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Class Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            prefixIcon: Icon(Icons.school),
                          ),
                          dropdownColor: AppTheme.surface,
                          value: _selectedClassId,
                          items: admin.classes
                              .map((c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClassId = val;
                              _selectedBatchId = null;
                              _selectedSubjectId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Batch Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Batch',
                            prefixIcon: Icon(Icons.groups),
                          ),
                          dropdownColor: AppTheme.surface,
                          value: _selectedBatchId,
                          items: filteredBatches
                              .map((b) => DropdownMenuItem<int>(
                                    value: b.id,
                                    child: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Subject Select (Optional)
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Subject (Optional)',
                            prefixIcon: Icon(Icons.book),
                          ),
                          dropdownColor: AppTheme.surface,
                          value: _selectedSubjectId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('General Attendance', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                            ...filteredSubjects.map((s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                ))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSubjectId = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Session Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppTheme.secondary),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SESSION DATE', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('dd MMMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              )
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  ElevatedButton(
                    onPressed: _handleStartSession,
                    child: const Text('Start Attendance Session'),
                  ),
                ],
              ),
            ),
    );
  }
}
