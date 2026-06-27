import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _serverUrlController = TextEditingController();
  final _whatsappUrlController = TextEditingController();
  final _whatsappKeyController = TextEditingController();
  
  bool _whatsappMock = true;
  bool _cloudinaryMock = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = ApiService().baseUrl;
    Future.microtask(() async {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      await admin.loadSettings();
      
      setState(() {
        _whatsappMock = admin.settings['whatsapp_mock_mode'] == 'true';
        _cloudinaryMock = admin.settings['cloudinary_mock_mode'] == 'true';
        _whatsappUrlController.text = admin.settings['whatsapp_api_url'] ?? '';
        _whatsappKeyController.text = admin.settings['whatsapp_api_key'] ?? '';
      });
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _whatsappUrlController.dispose();
    _whatsappKeyController.dispose();
    super.dispose();
  }

  void _saveLocalSettings() {
    final customUrl = _serverUrlController.text.trim();
    if (customUrl.isNotEmpty) {
      ApiService().setCustomBaseUrl(customUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App Server URL updated locally')),
      );
    }
  }

  void _saveServerSettings() async {
    setState(() {
      _isProcessing = true;
    });

    final admin = Provider.of<AdminProvider>(context, listen: false);
    
    try {
      await admin.updateSetting('whatsapp_mock_mode', _whatsappMock ? 'true' : 'false');
      await admin.updateSetting('cloudinary_mock_mode', _cloudinaryMock ? 'true' : 'false');
      await admin.updateSetting('whatsapp_api_url', _whatsappUrlController.text.trim());
      await admin.updateSetting('whatsapp_api_key', _whatsappKeyController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server Settings updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update server settings')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _runBackup() async {
    setState(() {
      _isProcessing = true;
    });

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final baseUrl = admin.settings['server_url'] ?? ApiService().baseUrl;

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/admin/backup'), headers: {
        'Authorization': 'Bearer ${admin.settings['jwt_token'] ?? ''}'
      });

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json').create();
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _isProcessing = false;
        });

        await Share.shareXFiles([XFile(file.path)], text: 'Database Backup File');
      } else {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup network error')),
      );
    }
  }

  void _runRestoreSimulated() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Restore Data', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Select a valid JSON backup file to restore database tables. WARNING: This will overwrite all current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload the backup file via server API `/api/admin/restore`')),
              );
            },
            child: const Text('Select File'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Server URL
                  const Text('App Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _serverUrlController,
                          decoration: const InputDecoration(
                            labelText: 'API Base URL',
                            prefixIcon: Icon(Icons.dns_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _saveLocalSettings,
                          child: const Text('Save API Base URL'),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Settings
                  const Text('Notification & Media Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title: const Text('WhatsApp Mock Mode', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: const Text('Log messages to console instead of sending real texts', style: TextStyle(fontSize: 12)),
                          activeColor: AppTheme.secondary,
                          value: _whatsappMock,
                          onChanged: (val) {
                            setState(() {
                              _whatsappMock = val;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Cloudinary Mock Mode', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: const Text('Store uploaded images locally on server', style: TextStyle(fontSize: 12)),
                          activeColor: AppTheme.secondary,
                          value: _cloudinaryMock,
                          onChanged: (val) {
                            setState(() {
                              _cloudinaryMock = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _whatsappUrlController,
                          decoration: const InputDecoration(labelText: 'WhatsApp API Gateway URL'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _whatsappKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'WhatsApp API Gateway Key'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveServerSettings,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                          child: const Text('Save Server Settings'),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Backup & Restore
                  const Text('Database Maintenance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _runBackup,
                            icon: const Icon(Icons.backup_outlined),
                            label: const Text('Backup DB'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary.withOpacity(0.8)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _runRestoreSimulated,
                            icon: const Icon(Icons.restore_outlined),
                            label: const Text('Restore DB'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
