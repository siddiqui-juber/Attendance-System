import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class StudentQrViewer extends StatelessWidget {
  final Student student;
  final bool showSuccessBanner;

  const StudentQrViewer({
    super.key,
    required this.student,
    this.showSuccessBanner = false,
  });

  Future<void> _shareQrCode(BuildContext context) async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final baseUrl = admin.settings['server_url'] ?? ApiService().baseUrl;
    final url = '$baseUrl/api/admin/students/${student.id}/qr-code';

    try {
      // Download the QR code bytes
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${admin.settings['jwt_token'] ?? ''}' // if needed, otherwise standard
      });

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/student_${student.studentId}_qr.png').create();
        await file.writeAsBytes(response.bodyBytes);

        // Share file
        await Share.shareXFiles([XFile(file.path)], text: 'QR Code for student ${student.name} (${student.studentId})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share QR Code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student QR Card'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSuccessBanner) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.secondary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Student Registered Successfully!',
                          style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // ID Card Layout
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Text(
                      student.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ROLL NO: ${student.rollNumber}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    
                    // Render Vector QR
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: student.qrCodeToken,
                        version: QrVersions.auto,
                        size: 200.0,
                        gapless: false,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      student.studentId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoText('CLASS', student.className),
                        _buildInfoText('BATCH', student.batchName),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => _shareQrCode(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share QR Code Digitally'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
