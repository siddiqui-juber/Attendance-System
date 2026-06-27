import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'student_qr_viewer.dart';

class RegisterStudent extends StatefulWidget {
  final Student? studentToEdit;

  const RegisterStudent({super.key, this.studentToEdit});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final _formKey = GlobalKey<FormState>();
  
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentMobileController = TextEditingController();
  final _parentWhatsAppController = TextEditingController();
  final _addressController = TextEditingController();

  int? _selectedClassId;
  int? _selectedBatchId;
  
  File? _imageFile;
  String _uploadedPhotoUrl = '';
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadClasses();
      admin.loadBatches();
      
      if (widget.studentToEdit != null) {
        final stu = widget.studentToEdit!;
        _studentIdController.text = stu.studentId;
        _nameController.text = stu.name;
        _rollController.text = stu.rollNumber;
        _parentNameController.text = stu.parentName;
        _parentMobileController.text = stu.parentMobile;
        _parentWhatsAppController.text = stu.parentWhatsApp;
        _addressController.text = stu.address;
        _selectedClassId = stu.classId;
        _selectedBatchId = stu.batchId;
        _uploadedPhotoUrl = stu.photoUrl;
      }
    });
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentMobileController.dispose();
    _parentWhatsAppController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      // Upload to server immediately
      final url = await ApiService().uploadImage('/api/admin/students/upload-photo', _imageFile!);
      
      setState(() {
        _isUploadingPhoto = false;
        if (url != null) {
          _uploadedPhotoUrl = url;
        }
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Class and Batch')),
      );
      return;
    }

    final admin = Provider.of<AdminProvider>(context, listen: false);
    
    if (widget.studentToEdit == null) {
      // Register new student
      final student = await admin.registerStudent(
        studentId: _studentIdController.text.trim(),
        name: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        classId: _selectedClassId!,
        batchId: _selectedBatchId!,
        parentName: _parentNameController.text.trim(),
        parentMobile: _parentMobileController.text.trim(),
        parentWhatsApp: _parentWhatsAppController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl: _uploadedPhotoUrl,
      );

      if (student != null && mounted) {
        // Direct transition to the generated student QR code card!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentQrViewer(student: student, showSuccessBanner: true),
          ),
        );
      }
    } else {
      // Update student
      final success = await admin.updateStudent(
        widget.studentToEdit!.id,
        name: _nameController.text.trim(),
        rollNumber: _rollController.text.trim(),
        classId: _selectedClassId!,
        batchId: _selectedBatchId!,
        parentName: _parentNameController.text.trim(),
        parentMobile: _parentMobileController.text.trim(),
        parentWhatsApp: _parentWhatsAppController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl: _uploadedPhotoUrl,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile updated!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final isEditing = widget.studentToEdit != null;

    final filteredBatches = admin.batches
        .where((b) => b.classId == _selectedClassId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'Register Student'),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Picker Section
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary, width: 2),
                              color: AppTheme.surface,
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : (_uploadedPhotoUrl.isNotEmpty
                                      ? Image.network(
                                          _uploadedPhotoUrl.startsWith('/uploads/')
                                              ? '${admin.settings['server_url'] ?? ApiService().baseUrl}$_uploadedPhotoUrl'
                                              : _uploadedPhotoUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.camera_alt_outlined, size: 40, color: AppTheme.textSecondary)),
                            ),
                          ),
                          if (_isUploadingPhoto)
                            const CircularProgressIndicator(color: AppTheme.secondary),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (c) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Choose from Gallery'),
                                            onTap: () {
                                              _pickImage(ImageSource.gallery);
                                              Navigator.pop(c);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.camera_alt),
                                            title: const Text('Take a Photo'),
                                            onTap: () {
                                              _pickImage(ImageSource.camera);
                                              Navigator.pop(c);
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Forms Fields
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Academic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          if (!isEditing) ...[
                            TextFormField(
                              controller: _studentIdController,
                              decoration: const InputDecoration(
                                labelText: 'Student ID (Optional, Autogenerated if empty)',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Student Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter student name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _rollController,
                            decoration: const InputDecoration(
                              labelText: 'Roll Number',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter roll number' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Class Dropdown
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              prefixIcon: Icon(Icons.school_outlined),
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
                                _selectedBatchId = null; // reset batch selection
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Batch Dropdown
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Batch',
                              prefixIcon: Icon(Icons.groups_outlined),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Parent Contact Details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Parent Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _parentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Parent Full Name',
                              prefixIcon: Icon(Icons.family_restroom_outlined),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter parent name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _parentMobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Parent Mobile Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter parent mobile number' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _parentWhatsAppController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Parent WhatsApp Number (Notifications)',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter parent WhatsApp number' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Address (Optional)',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: Text(isEditing ? 'Save Changes' : 'Register Student & Generate QR'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
