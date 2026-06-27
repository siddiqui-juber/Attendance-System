import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../login_screen.dart';
import 'manage_batches.dart';
import 'manage_students.dart';
import 'manage_teachers.dart';
import 'admin_reports.dart';
import 'admin_settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardStats();
    });
  }

  void _handleLogout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final stats = admin.stats;

    final double attendancePct = (stats['todayAttendancePercentage'] ?? 0.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.loadDashboardStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Branch Header
                    Text(
                      'Welcome, ${auth.userProfile?.name ?? "Admin"}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          auth.userProfile?.branches.join(', ') ?? 'Main Branch',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today's Attendance Radial Progress Card
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Attendance",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Present: ${stats['todayPresentCount'] ?? 0}  |  Absent: ${stats['todayAbsentCount'] ?? 0}",
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Status updated in real-time.",
                                  style: TextStyle(color: AppTheme.secondary.withOpacity(0.8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 85,
                                height: 85,
                                child: CircularProgressIndicator(
                                  value: attendancePct / 100,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                                ),
                              ),
                              Text(
                                '${attendancePct.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid Section
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard('Students', '${stats['totalStudents'] ?? 0}', Icons.people_outline, AppTheme.primary),
                        _buildStatCard('Teachers', '${stats['totalTeachers'] ?? 0}', Icons.school_outlined, AppTheme.secondary),
                        _buildStatCard('Batches', '${stats['totalBatches'] ?? 0}', Icons.batch_prediction_outlined, AppTheme.accent),
                        _buildStatCard('Branches', '${stats['totalBranches'] ?? 0}', Icons.storefront_outlined, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Administrative Controls
                    const Text(
                      'Management Tools',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        _buildToolBtn(context, 'Batches', Icons.grid_view_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBatches()));
                        }),
                        _buildToolBtn(context, 'Teachers', Icons.assignment_ind_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTeachers()));
                        }),
                        _buildToolBtn(context, 'Students', Icons.person_add_alt_1_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudents()));
                        }),
                        _buildToolBtn(context, 'Reports', Icons.analytics_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReports()));
                        }),
                        _buildToolBtn(context, 'Settings', Icons.tune_outlined, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettings()));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
