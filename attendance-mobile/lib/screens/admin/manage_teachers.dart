import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class ManageTeachers extends StatefulWidget {
  const ManageTeachers({super.key});

  @override
  State<ManageTeachers> createState() => _ManageTeachersState();
}

class _ManageTeachersState extends State<ManageTeachers> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.loadTeachers();
      admin.loadBranches();
    });
  }

  void _showTeacherForm({int? editTeacherId, String? currentName, String? currentEmail, String? currentUsername, List<String>? currentBranches}) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final usernameController = TextEditingController(text: currentUsername);
    final passwordController = TextEditingController();

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final List<int> selectedBranchIds = [];

    // Pre-populate branches if editing
    if (editTeacherId != null && currentBranches != null) {
      for (var bName in currentBranches) {
        final bMatch = admin.branches.firstWhere((element) => element.name == bName);
        selectedBranchIds.add(bMatch.id);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      editTeacherId == null ? 'Register New Teacher' : 'Edit Teacher Info',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    if (editTeacherId == null) ...[
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: editTeacherId == null ? 'Password' : 'New Password (Optional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Branches Checkboxes
                    const Text('Assign Branches', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: admin.branches.length,
                        itemBuilder: (c, idx) {
                          final branch = admin.branches[idx];
                          final isChecked = selectedBranchIds.contains(branch.id);
                          return CheckboxListTile(
                            title: Text(branch.name, style: const TextStyle(color: AppTheme.textPrimary)),
                            activeColor: AppTheme.primary,
                            value: isChecked,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  selectedBranchIds.add(branch.id);
                                } else {
                                  selectedBranchIds.remove(branch.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        final username = usernameController.text.trim();
                        final password = passwordController.text;

                        if (name.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
                          );
                          return;
                        }

                        bool success;
                        if (editTeacherId == null) {
                          if (username.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username and password are required')),
                            );
                            return;
                          }
                          success = await admin.registerTeacher(name, username, email, password, selectedBranchIds);
                        } else {
                          success = await admin.updateTeacher(editTeacherId, name, email, password, selectedBranchIds);
                        }

                        if (success && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(editTeacherId == null ? 'Teacher registered!' : 'Teacher details updated!')),
                          );
                        }
                      },
                      child: Text(editTeacherId == null ? 'Register Teacher' : 'Update Profile'),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : admin.teachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No teachers registered yet.', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: admin.teachers.length,
                  itemBuilder: (ctx, idx) {
                    final teacher = admin.teachers[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teacher.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@${teacher.username}  |  ${teacher.email}',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.secondary),
                                      onPressed: () => _showTeacherForm(
                                        editTeacherId: teacher.id,
                                        currentName: teacher.name,
                                        currentEmail: teacher.email,
                                        currentUsername: teacher.username,
                                        currentBranches: teacher.branches,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            backgroundColor: AppTheme.surface,
                                            title: const Text('Confirm Delete', style: TextStyle(color: AppTheme.textPrimary)),
                                            content: Text('Are you sure you want to delete teacher "${teacher.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(c),
                                                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                                onPressed: () {
                                                  admin.deleteTeacher(teacher.id);
                                                  Navigator.pop(c);
                                                },
                                                child: const Text('Delete'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 20),
                            const Text('Assigned Branches:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: teacher.branches.isEmpty
                                  ? [
                                       Chip(
                                        label: Text('None', style: TextStyle(fontSize: 11)),
                                        backgroundColor:Colors.white.withOpacity(0.05),
                                      )
                                    ]
                                  : teacher.branches
                                      .map((b) => Chip(
                                            label: Text(b, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                                            side: BorderSide.none,
                                          ))
                                      .toList(),
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
