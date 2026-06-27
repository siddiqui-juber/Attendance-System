import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  int? _selectedClassId;
  int? _selectedBatchId;
  int? _selectedStudentId;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadClasses();
      admin.loadBatches();
      admin.loadStudents();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
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
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _downloadReport(String format) async {
    setState(() {
      _isDownloading = true;
    });

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final baseUrl = admin.settings['server_url'] ?? ApiService().baseUrl;
    
    final formatter = DateFormat('yyyy-MM-dd');
    final startStr = formatter.format(_startDate);
    final endStr = formatter.format(_endDate);

    var urlStr = '$baseUrl/api/reports/$format?startDate=$startStr&endDate=$endStr';
    if (_selectedClassId != null) urlStr += '&classId=$_selectedClassId';
    if (_selectedBatchId != null) urlStr += '&batchId=$_selectedBatchId';
    if (_selectedStudentId != null) urlStr += '&studentId=$_selectedStudentId';

    try {
      final response = await http.get(Uri.parse(urlStr), headers: {
        'Authorization': 'Bearer ${admin.settings['jwt_token'] ?? ''}'
      });

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final ext = format == 'excel' ? 'xlsx' : 'pdf';
        final file = await File('${tempDir.path}/attendance_report_${DateTime.now().millisecondsSinceEpoch}.$ext').create();
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _isDownloading = false;
        });

        // Share the downloaded report
        await Share.shareXFiles([XFile(file.path)], text: 'Attendance Report ($startStr to $endStr)');
      } else {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate report (server error)')),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error downloading report')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final filteredBatches = admin.batches
        .where((b) => b.classId == _selectedClassId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: admin.isLoading || _isDownloading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing report download...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    child: Column(
                      children: [
                        // Class Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Class (Optional)'),
                          dropdownColor: AppTheme.surface,
                          value: _selectedClassId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All Classes', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                            ...admin.classes.map((c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                ))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedClassId = val;
                              _selectedBatchId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Batch Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Batch (Optional)'),
                          dropdownColor: AppTheme.surface,
                          value: _selectedBatchId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All Batches', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                            ...filteredBatches.map((b) => DropdownMenuItem<int>(
                                  value: b.id,
                                  child: Text(b.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                ))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Student Select
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Student (Optional)'),
                          dropdownColor: AppTheme.surface,
                          value: _selectedStudentId,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All Students', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                            ...admin.students.map((s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.name, style: const TextStyle(color: AppTheme.textPrimary)),
                                ))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedStudentId = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Range Selector
                  const Text('Select Date Range', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('START DATE', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('END DATE', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Download Buttons
                  ElevatedButton.icon(
                    onPressed: () => _downloadReport('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export to PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _downloadReport('excel'),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Export to Excel (.xlsx)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
