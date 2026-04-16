// ─── lib/screens/admin/admin_dashboard.dart ───────────────────────────────

import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/intern_user.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/intern_list_card.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import 'add_intern_screen.dart';
import 'assign_task_screen.dart';
import 'intern_profile_screen.dart';
import 'task_review_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _db = FirestoreService();
  late TabController _tabCtrl;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _currentTab = _tabCtrl.index));
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Column(children: [
          Text('Admin Panel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          Text('Internee.pk IMS',
              style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF), fontWeight: FontWeight.w400)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _confirmLogout)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded, size: 17), text: 'Interns'),
            Tab(icon: Icon(Icons.task_rounded, size: 17), text: 'Tasks'),
            Tab(icon: Icon(Icons.rate_review_rounded, size: 17), text: 'Review'),
          ],
        ),
      ),
      body: Column(children: [
        // Stats banner — full width background, centered content
        _buildStatsBanner(),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _InternTab(db: _db),
              _TaskTab(db: _db),
              _ReviewTab(db: _db),
            ],
          ),
        ),
      ]),
      floatingActionButton: _currentTab == 2 ? null :
        FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          onPressed: () {
            if (_currentTab == 0) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInternScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignTaskScreen()));
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(_currentTab == 0 ? 'Add Intern' : 'Assign Task'),
        ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      width: double.infinity,
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: R.wrap(
        child: FutureBuilder<Map<String, int>>(
          future: _db.getInternStats(),
          builder: (ctx, snap) {
            final s = snap.data ?? {'active': 0, 'completed': 0, 'inactive': 0};
            final total = (s['active']! + s['completed']! + s['inactive']!);
            return Row(children: [
              _statItem('Active', s['active']!, AppTheme.accent),
              _divider(),
              _statItem('Graduated', s['completed']!, const Color(0xFF3B82F6)),
              _divider(),
              _statItem('Inactive', s['inactive']!, Colors.orange),
              _divider(),
              _statItem('Total', total, Colors.white),
            ]);
          },
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) => Expanded(
    child: Column(children: [
      Text('$count', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10),
          overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 28, color: Colors.white.withOpacity(0.12));

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }
}

// ── Interns Tab ────────────────────────────────────────────────────────────
class _InternTab extends StatefulWidget {
  final FirestoreService db;
  const _InternTab({required this.db});
  @override
  State<_InternTab> createState() => _InternTabState();
}

class _InternTabState extends State<_InternTab> {
  String _search = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InternUser>>(
      stream: widget.db.getAllInterns(),
      builder: (ctx, snap) {
        final interns = snap.data ?? [];
        final filtered = interns.where((i) {
          final ms = _search.isEmpty ||
              i.name.toLowerCase().contains(_search.toLowerCase()) ||
              i.email.toLowerCase().contains(_search.toLowerCase()) ||
              i.department.toLowerCase().contains(_search.toLowerCase());
          final mf = _filterStatus == 'all' || i.status == _filterStatus;
          return ms && mf;
        }).toList();

        return Column(children: [
          // Search row — full width bg, centered content
          Container(
            width: double.infinity,
            color: AppTheme.surface,
            child: R.wrap(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search interns...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.accent, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 13),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          if (filtered.isEmpty)
            const Expanded(child: Center(
              child: Text('No interns found', style: TextStyle(color: AppTheme.textLight))))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => R.wrap(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InternListCard(
                      intern: filtered[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InternProfileScreen(intern: filtered[i]))),
                    ),
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

// ── Tasks Tab ──────────────────────────────────────────────────────────────
class _TaskTab extends StatefulWidget {
  final FirestoreService db;
  const _TaskTab({required this.db});
  @override
  State<_TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends State<_TaskTab> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: widget.db.getAllTasks(),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];
        final filtered = _filterStatus == 'all'
            ? tasks
            : tasks.where((t) => t.status == _filterStatus).toList();

        return Column(children: [
          // Filter chips
          Container(
            width: double.infinity,
            color: AppTheme.surface,
            child: R.wrap(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'pending', 'in_progress', 'submitted', 'completed']
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _filterChip(s),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No tasks found',
                    style: TextStyle(color: AppTheme.textLight)))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => R.wrap(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TaskCard(task: filtered[i], isIntern: false, showAssignee: true),
                      ),
                    ),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _filterChip(String status) {
    final labels = {'all': 'All', 'pending': 'Pending', 'in_progress': 'In Progress',
        'submitted': 'Submitted', 'completed': 'Completed'};
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(labels[status] ?? status,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textMid,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13)),
      ),
    );
  }
}

// ── Review Tab ─────────────────────────────────────────────────────────────
class _ReviewTab extends StatelessWidget {
  final FirestoreService db;
  const _ReviewTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskModel>>(
      stream: db.getSubmittedTasksForReview(),
      builder: (ctx, snap) {
        final tasks = snap.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.rate_review_outlined, size: 60, color: AppTheme.textLight.withOpacity(0.35)),
              const SizedBox(height: 14),
              const Text('No submissions to review',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Intern submissions will appear here.',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            ]),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            R.wrap(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 16),
                    const SizedBox(width: 8),
                    Text('${tasks.length} submission(s) awaiting your review',
                        style: const TextStyle(color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w500, fontSize: 13)),
                  ]),
                ),
              ),
            ),
            ...tasks.map((task) => R.wrap(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _ReviewCard(
                  task: task,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => TaskReviewScreen(taskId: task.id))),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  const _ReviewCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rate_review_rounded, color: Color(0xFF8B5CF6), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${task.assignedToName}  •  ${task.links.length} link(s)',
                style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textLight),
        ]),
      ),
    );
  }
}
