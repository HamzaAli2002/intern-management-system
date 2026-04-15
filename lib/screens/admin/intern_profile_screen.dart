// ─── lib/screens/admin/intern_profile_screen.dart ─────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../models/intern_user.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/task_card.dart';
import '../../widgets/progress_ring.dart';

class InternProfileScreen extends StatelessWidget {
  final InternUser intern;
  const InternProfileScreen({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final df = DateFormat('MMM dd, yyyy');
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad = isTablet ? (sw * 0.08).clamp(0.0, 120.0) : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ──
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1A3A5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                // Use SafeArea + padding instead of fixed SizedBox to avoid overflow
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.accent.withOpacity(0.2),
                          child: Text(
                            intern.name.isNotEmpty ? intern.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 26,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(intern.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${intern.department} • ${intern.batchNo}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (v) => _handleAction(context, v, db),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'active',
                      child: Row(children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('Set Active')
                      ])),
                  const PopupMenuItem(
                      value: 'completed',
                      child: Row(children: [
                        Icon(Icons.school_outlined, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Set Completed')
                      ])),
                  const PopupMenuItem(
                      value: 'inactive',
                      child: Row(children: [
                        Icon(Icons.pause_circle_outline, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text('Set Inactive')
                      ])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete Intern', style: TextStyle(color: Colors.red))
                      ])),
                ],
              ),
            ],
          ),

          // ── Content ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Progress card
                _card(
                  title: 'Progress',
                  child: Row(children: [
                    ProgressRing(
                      progress: intern.progressPercent,
                      size: 68,
                      color: AppTheme.accent,
                      label: '${(intern.progressPercent * 100).toStringAsFixed(0)}%',
                    ),
                    const SizedBox(width: 20),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${intern.completedTasks}/${intern.totalTasks}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                      const Text('Tasks Done',
                          style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),

                // Profile info card
                _card(
                  title: 'Profile Information',
                  child: Column(children: [
                    _infoRow(Icons.email_outlined, 'Email', intern.email),
                    const Divider(height: 18),
                    _infoRow(Icons.phone_outlined, 'Phone',
                        intern.phone.isNotEmpty ? intern.phone : '—'),
                    const Divider(height: 18),
                    _infoRow(Icons.calendar_today_outlined, 'Joined',
                        df.format(intern.joinDate)),
                    const Divider(height: 18),
                    _infoRow(Icons.circle, 'Status',
                        intern.status.toUpperCase(),
                        color: _statusColor(intern.status)),
                  ]),
                ),
                const SizedBox(height: 20),

                const Text('Assigned Tasks',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 10),
              ]),
            ),
          ),

          // ── Tasks ──
          StreamBuilder<List<TaskModel>>(
            stream: db.getTasksForIntern(intern.uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                    child: Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator())));
              }
              final tasks = snap.data ?? [];
              if (tasks.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No tasks assigned yet',
                          style: TextStyle(color: AppTheme.textLight)),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    (MediaQuery.of(ctx).size.width >= 600
                            ? MediaQuery.of(ctx).size.width * 0.08
                            : 16.0)
                        .clamp(0.0, 120.0),
                    0,
                    (MediaQuery.of(ctx).size.width >= 600
                            ? MediaQuery.of(ctx).size.width * 0.08
                            : 16.0)
                        .clamp(0.0, 120.0),
                    100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(task: tasks[i], isIntern: false),
                    ),
                    childCount: tasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
                letterSpacing: 0.4)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 17, color: AppTheme.accent),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ]),
      ),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active': return AppTheme.accent;
      case 'completed': return const Color(0xFF3B82F6);
      default: return Colors.orange;
    }
  }

  void _handleAction(BuildContext context, String action, FirestoreService db) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Intern'),
          content: Text('Delete ${intern.name}? This also deletes all their tasks.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await db.deleteIntern(intern.uid);
        if (context.mounted) Navigator.pop(context);
      }
    } else {
      await db.updateInternStatus(intern.uid, action);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $action'),
          backgroundColor: AppTheme.accent,
        ));
      }
    }
  }
}
