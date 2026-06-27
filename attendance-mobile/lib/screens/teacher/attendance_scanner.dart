import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/attendance_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'attendance_summary.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';

class AttendanceScanner extends StatefulWidget {
  const AttendanceScanner({super.key});

  @override
  State<AttendanceScanner> createState() => _AttendanceScannerState();
}

class _AttendanceScannerState extends State<AttendanceScanner> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessingScan = true;
    });

    // Vibrate/Feedback for detection
    Feedback.forTap(context);

    final att = Provider.of<AttendanceProvider>(context, listen: false);
    final result = await att.scanQrCode(rawValue);
    
    if (mounted) {
      _showScanResultDialog(result);
    }
  }

  void _showScanResultDialog(Map<String, dynamic> result) {
    final bool success = result['success'] ?? false;
    final bool isDuplicate = result['isDuplicate'] ?? false;
    final String message = result['message'] ?? '';
    final Student? student = result['student'] as Student?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Auto dismiss after 2 seconds
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
            setState(() {
              _isProcessingScan = false;
            });
          }
        });

        // Resolve Photo URL
        String photoUrl = '';
        if (student != null && student.photoUrl.isNotEmpty) {
          photoUrl = student.photoUrl.startsWith('/uploads/')
              ? '${Provider.of<AdminProvider>(context, listen: false).settings['server_url'] ?? ApiService().baseUrl}${student.photoUrl}'
              : student.photoUrl;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: GlassCard(
            borderRadius: 30,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan Icon Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: success 
                        ? Colors.green.withOpacity(0.15) 
                        : (isDuplicate ? Colors.amber.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success 
                        ? Icons.check_circle_outline 
                        : (isDuplicate ? Icons.warning_amber_outlined : Icons.error_outline),
                    color: success 
                        ? Colors.green 
                        : (isDuplicate ? Colors.amber : Colors.redAccent),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status Text
                Text(
                  success 
                      ? 'Marked Present!' 
                      : (isDuplicate ? 'Already Scanned!' : 'Scan Failed'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: success 
                        ? Colors.green 
                        : (isDuplicate ? Colors.amber : Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 20),

                // Student Details if matched
                if (student != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: student.photoUrl.isEmpty
                        ? Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.primary.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppTheme.primary, size: 40),
                          )
                        : Image.network(
                            photoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 80,
                              height: 80,
                              color: AppTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.person, color: AppTheme.primary, size: 40),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${student.rollNumber}  |  ID: ${student.studentId}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ] else ...[
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final att = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Camera Scanner View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // 2. Translucent Camera Overlay Frame
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scan Frame Corner Border Decors
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _ScannerBorderPainter(),
            ),
          ),

          // 4. Header Bar (Glass Layout)
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          att.activeBatch?.name ?? 'Scanner Active',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'Scanned: ${att.presentStudents.length} / ${att.batchStudents.length}',
                          style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: AppTheme.textPrimary),
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),

          // 5. Footer "Review & Submit" Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                _scannerController.stop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceSummary()),
                );
              },
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Review Scanned Students'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.primary,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final path = Path();
    const double length = 25.0;

    // Top Left Corner
    path.moveTo(0, length);
    path.lineTo(0, 0);
    path.lineTo(length, 0);

    // Top Right Corner
    path.moveTo(size.width - length, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, length);

    // Bottom Right Corner
    path.moveTo(size.width, size.height - length);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - length, size.height);

    // Bottom Left Corner
    path.moveTo(length, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
