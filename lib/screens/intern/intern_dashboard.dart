// ─── lib/screens/intern/intern_dashboard.dart ─────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InternUser?>(
      stream: _db.streamInternById(widget.uid),
      builder: (context, userSnap) {
        final intern = userSnap.data;
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            title: Column(
              children: [
                const Text('My Dashboard',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                if (intern != null)
                  Text(
                    intern.name,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w400),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _confirmLogout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: StreamBuilder<List<TaskModel>>(
            stream: _db.getTasksForIntern(widget.uid),
            builder: (context, taskSnap) {
              final allTasks = taskSnap.data ?? [];
              final tabs = ['All', 'Pending', 'In Progress', 'Submitted', 'Completed'];
              final filtered = _filterTasks(allTasks, _selectedTab);
              final sw = MediaQuery.of(context).size.width;
              final isTablet = sw >= 600;
              final hPad = isTablet ? sw * 0.08 : 0.0;

              return CustomScrollView(
                slivers: [
                  // ── Profile Header ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildProfileHeader(intern, allTasks),
                    ),
                  ),

                  // ── Stat Cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildStatRow(allTasks),
                    ),
                  ),

                  // ── Filter Tabs ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _buildFilterTabs(tabs),
                    ),
                  ),

                  // ── Tasks ──
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          16 + hPad, 0, 16 + hPad, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TaskCard(
                              task: filtered[i],
                              isIntern: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskDetailScreen(
                                    taskId: filtered[i].id,
                                    internUid: widget.uid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

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
                t.status == 'completed' ||
                t.adminReviewStatus == 'approved')
            .toList();
      default:
        return tasks;
    }
  }

  Widget _buildProfileHeader(InternUser? intern, List<TaskModel> tasks) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.accent.withOpacity(0.2),
            child: Text(
              intern?.name.isNotEmpty == true
                  ? intern!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intern?.name ?? 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intern?.department ?? '',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(intern?.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (intern?.status ?? 'active').toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(intern?.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            progress: intern?.progressPercent ?? 0,
            size: 64,
            color: AppTheme.accent,
            label:
                '${((intern?.progressPercent ?? 0) * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(List<TaskModel> tasks) {
    final pending = tasks.where((t) => t.status == 'pending').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final submitted = tasks.where((t) => t.status == 'submitted').length;
    final completed = tasks.where((t) => t.status == 'completed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statChip('Pending', pending, const Color(0xFFFF6E40),
              Icons.hourglass_empty_rounded),
          const SizedBox(width: 8),
          _statChip('Active', inProgress, const Color(0xFF3B82F6),
              Icons.autorenew_rounded),
          const SizedBox(width: 8),
          _statChip('Submitted', submitted, const Color(0xFF8B5CF6),
              Icons.upload_rounded),
          const SizedBox(width: 8),
          _statChip('Done', completed, AppTheme.accent,
              Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(List<String> tabs) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFE2E8F0)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textMid,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded,
              size: 64, color: AppTheme.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No tasks here',
            style: TextStyle(
                color: AppTheme.textMid,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tasks assigned by admin will appear here.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
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
