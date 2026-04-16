// ─── lib/screens/intern/intern_dashboard.dart ─────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../utils/responsive.dart';
import '../../models/intern_user.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/task_card.dart';
import '../../widgets/progress_ring.dart';
import '../auth/login_screen.dart';
import 'task_detail_screen.dart';

class InternDashboard extends StatefulWidget {
  final String uid;
  const InternDashboard({super.key, required this.uid});

  @override
  State<InternDashboard> createState() => _InternDashboardState();
}

class _InternDashboardState extends State<InternDashboard> {
  final _auth = AuthService();
  final _db = FirestoreService();
  int _selectedTab = 0;

  List<TaskModel> _filterTasks(List<TaskModel> tasks, int tab) {
    switch (tab) {
      case 1:
        return tasks.where((t) => t.status == 'pending').toList();
      case 2:
        return tasks.where((t) => t.status == 'in_progress').toList();
      case 3:
        return tasks.where((t) => t.status == 'submitted').toList();
      case 4:
        return tasks
            .where((t) =>
                t.status == 'completed' || t.adminReviewStatus == 'approved')
            .toList();
      default:
        return tasks;
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'active':
        return AppTheme.accent;
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'inactive':
        return Colors.orange;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return StreamBuilder<InternUser?>(
      stream: _db.streamInternById(widget.uid),
      builder: (context, userSnap) {
        final intern = userSnap.data;
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('My Dashboard',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                if (intern != null)
                  Text(intern.name,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w400)),
              ],
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _confirmLogout)
            ],
          ),
          body: StreamBuilder<List<TaskModel>>(
            stream: _db.getTasksForIntern(widget.uid),
            builder: (context, taskSnap) {
              // Show loading only on very first load with no data
              if (taskSnap.connectionState == ConnectionState.waiting &&
                  !taskSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allTasks = taskSnap.data ?? [];
              final tabs = ['All', 'Pending', 'Active', 'Submitted', 'Done'];
              final filtered = _filterTasks(allTasks, _selectedTab);

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Profile Header ──
                  R.wrap(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildProfileHeader(intern, allTasks, sw),
                  )),

                  // ── Stat Row ──
                  R.wrap(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildStatRow(allTasks, sw),
                  )),

                  // ── Filter Tabs ──
                  R.wrap(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildFilterTabs(tabs),
                  )),

                  // ── Task List or Empty ──
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    R.wrap(
                        child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        children: filtered
                            .map((task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(
                                    task: task,
                                    isIntern: true,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailScreen(
                                          taskId: task.id,
                                          internUid: widget.uid,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    )),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      InternUser? intern, List<TaskModel> tasks, double sw) {
    final isSmall = sw < 380;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      padding: EdgeInsets.all(isSmall ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmall ? 26 : 32,
            backgroundColor: AppTheme.accent.withOpacity(0.2),
            child: Text(
              intern?.name.isNotEmpty == true
                  ? intern!.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: isSmall ? 20 : 24,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intern?.name ?? 'Loading...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 15 : 17,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  intern?.department ?? '',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(intern?.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (intern?.status ?? 'active').toUpperCase(),
                    style: TextStyle(
                        color: _statusColor(intern?.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            progress: intern?.progressPercent ?? 0,
            size: isSmall ? 52 : 62,
            color: AppTheme.accent,
            label:
                '${((intern?.progressPercent ?? 0) * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(List<TaskModel> tasks, double sw) {
    final pending = tasks.where((t) => t.status == 'pending').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final submitted = tasks.where((t) => t.status == 'submitted').length;
    final completed = tasks.where((t) => t.status == 'completed').length;
    final isSmall = sw < 380;

    return Row(children: [
      _statChip('Pending', pending, const Color(0xFFFF6E40),
          Icons.hourglass_empty_rounded, isSmall),
      const SizedBox(width: 6),
      _statChip('Active', inProgress, const Color(0xFF3B82F6),
          Icons.autorenew_rounded, isSmall),
      const SizedBox(width: 6),
      _statChip('Sent', submitted, const Color(0xFF8B5CF6),
          Icons.upload_rounded, isSmall),
      const SizedBox(width: 6),
      _statChip('Done', completed, AppTheme.accent,
          Icons.check_circle_outline_rounded, isSmall),
    ]);
  }

  Widget _statChip(
      String label, int count, Color color, IconData icon, bool small) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: small ? 10 : 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: small ? 18 : 20),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: small ? 16 : 18,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: small ? 9 : 10,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildFilterTabs(List<String> tabs) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        selected ? AppTheme.primary : const Color(0xFFE2E8F0)),
              ),
              child: Text(tabs[i],
                  style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textMid,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded,
                size: 56, color: AppTheme.textLight.withOpacity(0.4)),
            const SizedBox(height: 14),
            const Text('No tasks here',
                style: TextStyle(
                    color: AppTheme.textMid,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            const Text('Tasks assigned by admin will appear here.',
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }
}
