import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../models/models.dart';

class ManageBatches extends StatefulWidget {
  const ManageBatches({super.key});

  @override
  State<ManageBatches> createState() => _ManageBatchesState();
}

class _ManageBatchesState extends State<ManageBatches> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminProvider>(context, listen: false).loadMetadata();
    });
  }

  void _showAddDialog(String type, Function(String) onSubmit, {List<DropdownMenuItem<int>>? dropdownItems, ValueChanged<int?>? onDropdownChanged}) {
    final textController = TextEditingController();
    int? selectedId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Add New $type', style: const TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: '$type Name',
                    ),
                  ),
                  if (dropdownItems != null) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                      ),
                      dropdownColor: AppTheme.surface,
                      items: dropdownItems,
                      value: selectedId,
                      onChanged: (val) {
                        setDialogState(() {
                          selectedId = val;
                        });
                        if (onDropdownChanged != null) {
                          onDropdownChanged!(val);
                        }
                      },
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = textController.text.trim();
                    if (name.isNotEmpty) {
                      if (dropdownItems != null && selectedId == null) {
                        // Class ID required for batches/subjects
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a class')),
                        );
                        return;
                      }
                      if (dropdownItems != null) {
                        onSubmit('$name|$selectedId');
                      } else {
                        onSubmit(name);
                      }
                      Navigator.pop(ctx);
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
    final admin = Provider.of<AdminProvider>(context);

    final classDropdownItems = admin.classes
        .map((c) => DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.name, style: const TextStyle(color: AppTheme.textPrimary)),
            ))
        .toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academic Metadata'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Branches'),
              Tab(text: 'Classes'),
              Tab(text: 'Batches'),
              Tab(text: 'Subjects'),
            ],
          ),
        ),
        body: admin.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Branches
                  _buildTabContent(
                    items: admin.branches,
                    title: 'Branch',
                    onAdd: () => _showAddDialog('Branch', (val) {
                      admin.createBranch(val);
                    }),
                    onDelete: (id) => admin.deleteBranch(id),
                  ),
                  // Tab 2: Classes
                  _buildTabContent(
                    items: admin.classes,
                    title: 'Class',
                    onAdd: () => _showAddDialog('Class', (val) {
                      admin.createClass(val);
                    }),
                    onDelete: (id) => admin.deleteClass(id),
                  ),
                  // Tab 3: Batches
                  _buildTabContent(
                    items: admin.batches,
                    title: 'Batch',
                    onAdd: () => _showAddDialog(
                      'Batch',
                      (val) {
                        final parts = val.split('|');
                        admin.createBatch(parts[0], int.parse(parts[1]));
                      },
                      dropdownItems: classDropdownItems,
                    ),
                    onDelete: (id) => admin.deleteBatch(id),
                    subtitleGetter: (item) => 'Class: ${(item as Batch).className}',
                  ),
                  // Tab 4: Subjects
                  _buildTabContent(
                    items: admin.subjects,
                    title: 'Subject',
                    onAdd: () => _showAddDialog(
                      'Subject',
                      (val) {
                        final parts = val.split('|');
                        admin.createSubject(parts[0], int.parse(parts[1]));
                      },
                      dropdownItems: classDropdownItems,
                    ),
                    onDelete: (id) => admin.deleteSubject(id),
                    subtitleGetter: (item) => 'Class: ${(item as Subject).className}',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabContent({
    required List<dynamic> items,
    required String title,
    required VoidCallback onAdd,
    required Function(int) onDelete,
    String Function(dynamic)? subtitleGetter,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('Add New $title'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No ${title}es found', style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final item = items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (subtitleGetter != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitleGetter(item),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ]
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: AppTheme.surface,
                                    title: const Text('Confirm Delete', style: TextStyle(color: AppTheme.textPrimary)),
                                    content: Text('Are you sure you want to delete "${item.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () {
                                          onDelete(item.id);
                                          Navigator.pop(c);
                                        },
                                        child: const Text('Delete'),
                                      )
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
