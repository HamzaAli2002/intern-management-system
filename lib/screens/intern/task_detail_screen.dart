// ─── lib/screens/intern/task_detail_screen.dart ───────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String internUid;

  const TaskDetailScreen(
      {super.key, required this.taskId, required this.internUid});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _noteCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _otherLinkCtrl = TextEditingController();
  final _otherLabelCtrl = TextEditingController();
  final _db = FirestoreService();
  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _noteInitialized = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _otherLinkCtrl.dispose();
    _otherLabelCtrl.dispose();
    super.dispose();
  }

  void _initFields(TaskModel task) {
    if (_noteInitialized) return;
    _noteInitialized = true;
    if (task.submissionNote != null) _noteCtrl.text = task.submissionNote!;
    for (final link in task.links) {
      if (link.isGitHub && _githubCtrl.text.isEmpty)
        _githubCtrl.text = link.url;
      if (link.isLinkedIn && _linkedinCtrl.text.isEmpty)
        _linkedinCtrl.text = link.url;
      if (link.type == 'other' && _otherLinkCtrl.text.isEmpty) {
        _otherLinkCtrl.text = link.url;
        _otherLabelCtrl.text = link.label;
      }
    }
  }

  List<TaskSubmissionLink> _buildLinks() {
    final links = <TaskSubmissionLink>[];
    if (_githubCtrl.text.trim().isNotEmpty) {
      links.add(TaskSubmissionLink(
          type: 'github',
          url: _githubCtrl.text.trim(),
          label: 'GitHub Repository'));
    }
    if (_linkedinCtrl.text.trim().isNotEmpty) {
      links.add(TaskSubmissionLink(
          type: 'linkedin',
          url: _linkedinCtrl.text.trim(),
          label: 'LinkedIn Post'));
    }
    if (_otherLinkCtrl.text.trim().isNotEmpty) {
      links.add(TaskSubmissionLink(
        type: 'other',
        url: _otherLinkCtrl.text.trim(),
        label: _otherLabelCtrl.text.trim().isNotEmpty
            ? _otherLabelCtrl.text.trim()
            : 'Link',
      ));
    }
    return links;
  }

  bool _validateSubmission() {
    return _noteCtrl.text.trim().isNotEmpty ||
        _githubCtrl.text.trim().isNotEmpty ||
        _linkedinCtrl.text.trim().isNotEmpty ||
        _otherLinkCtrl.text.trim().isNotEmpty;
  }

  Future<void> _submitTask(TaskModel task) async {
    if (!_validateSubmission()) {
      _showSnack('Add at least a GitHub link, LinkedIn post, or a note.',
          Colors.orange);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final links = _buildLinks();
      final note = _noteCtrl.text.trim();
      if (task.adminReviewStatus == 'needs_revision') {
        await _db.resubmitTask(
          taskId: task.id,
          submissionNote: note.isNotEmpty ? note : null,
          links: links,
        );
      } else {
        await _db.submitTask(
          taskId: task.id,
          internUid: widget.internUid,
          submissionNote: note.isNotEmpty ? note : null,
          links: links,
        );
      }
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSubmitting = false;
      });
      _showSnack('Task submitted for review!', AppTheme.accent);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnack('Submission failed: $e', Colors.red);
    }
  }

  Future<void> _startTask(String taskId) async {
    await _db.updateTaskStatus(taskId, 'in_progress');
    _showSnack('Task started!', const Color(0xFF3B82F6));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _openUrl(String url) async {
    final finalUrl =
        url.trim().startsWith('http') ? url.trim() : 'https://${url.trim()}';
    try {
      await launchUrl(Uri.parse(finalUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.platformDefault);
      } catch (e) {
        _showSnack('Cannot open link. Copy it manually.', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isTablet = sw >= 600;
    final hPad = isTablet ? sw * 0.1 : 16.0;

    return StreamBuilder<TaskModel?>(
      stream: _db.streamTask(widget.taskId),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final task = snap.data!;
        _initFields(task);

        final canSubmit = task.status == 'pending' ||
            task.status == 'in_progress' ||
            task.adminReviewStatus == 'needs_revision';
        final isSubmitted = task.status == 'submitted';
        final isCompleted = task.status == 'completed';
        final canEdit = !isCompleted && task.adminReviewStatus != 'approved';
        final df = DateFormat('MMM dd, yyyy');

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              if (canEdit && !_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 18),
                  label:
                      const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
              if (_isEditing)
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _statusBadge(task.status),
                  _priorityBadge(task.priority),
                  _categoryChip(task.category),
                ]),
                const SizedBox(height: 18),

                // Title
                Text(task.title,
                    style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 12),

                // Description
                _card(
                    child: Text(task.description,
                        style: const TextStyle(
                            color: AppTheme.textMid,
                            fontSize: 14,
                            height: 1.65))),
                const SizedBox(height: 14),

                // Dates
                _card(
                    child: Column(children: [
                  _infoRow(Icons.calendar_today_outlined, 'Due Date',
                      df.format(task.dueDate),
                      color: task.isOverdue ? Colors.red : AppTheme.textDark),
                  const Divider(height: 18),
                  _infoRow(Icons.add_task_rounded, 'Assigned',
                      df.format(task.createdAt)),
                  if (task.submittedAt != null) ...[
                    const Divider(height: 18),
                    _infoRow(Icons.upload_rounded, 'Submitted',
                        df.format(task.submittedAt!),
                        color: const Color(0xFF3B82F6)),
                  ],
                  if (task.completedAt != null) ...[
                    const Divider(height: 18),
                    _infoRow(Icons.check_circle_outline_rounded, 'Approved',
                        df.format(task.completedAt!),
                        color: AppTheme.accent),
                  ],
                ])),

                if (task.isOverdue) ...[
                  const SizedBox(height: 12),
                  _banner('This task is overdue!', Colors.red,
                      icon: Icons.warning_amber_rounded),
                ],

                // Admin remark
                if (task.hasReview) ...[
                  const SizedBox(height: 20),
                  _remarkCard(task),
                ],

                // Submitted links (read-only when not editing)
                if (task.links.isNotEmpty && !_isEditing) ...[
                  const SizedBox(height: 20),
                  _sectionLabel('Submitted Links'),
                  const SizedBox(height: 10),
                  ...task.links.map((l) => _linkTile(l)),
                ],

                // Submitted note (read-only)
                if (task.submissionNote != null &&
                    task.submissionNote!.isNotEmpty &&
                    !_isEditing) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Submission Note'),
                  const SizedBox(height: 8),
                  _card(
                      child: Text(task.submissionNote!,
                          style: const TextStyle(
                              color: AppTheme.textMid,
                              fontSize: 14,
                              height: 1.55))),
                ],

                // Submission form
                if (_isEditing || canSubmit) ...[
                  const SizedBox(height: 24),
                  _sectionLabel(_isEditing ? 'Edit Submission' : 'Submit Task'),
                  const SizedBox(height: 4),
                  const Text('Add your GitHub repo and/or LinkedIn post link',
                      style:
                          TextStyle(color: AppTheme.textLight, fontSize: 12)),
                  const SizedBox(height: 14),
                  _linkField(
                      controller: _githubCtrl,
                      label: 'GitHub Repository URL',
                      hint: 'https://github.com/username/repo-name',
                      icon: Icons.code_rounded,
                      color: const Color(0xFF24292F)),
                  const SizedBox(height: 12),
                  _linkField(
                      controller: _linkedinCtrl,
                      label: 'LinkedIn Post URL',
                      hint: 'https://linkedin.com/posts/your-post-id',
                      icon: Icons.work_outline_rounded,
                      color: const Color(0xFF0A66C2)),
                  const SizedBox(height: 12),
                  _linkField(
                      controller: _otherLinkCtrl,
                      label: 'Other Link (optional)',
                      hint: 'https://example.com/demo',
                      icon: Icons.link_rounded,
                      color: const Color(0xFF8B5CF6)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otherLabelCtrl,
                    decoration: _inputDec(
                        'Label for other link',
                        'e.g. Live Demo, Figma, Drive',
                        Icons.label_outline_rounded,
                        AppTheme.textLight),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 4,
                    decoration: _inputDec(
                        'Description / Notes',
                        'What did you build? What challenges did you face? What did you learn?',
                        Icons.notes_rounded,
                        AppTheme.textLight,
                        alignHint: true),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded,
                              color: AppTheme.accent, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: Push code to GitHub → Post on LinkedIn → Paste both links here.',
                              style: TextStyle(
                                  color: AppTheme.textMid,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ]),
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                if (task.status == 'pending') ...[
                  _actionBtn('Start Task', Icons.play_arrow_rounded,
                      const Color(0xFF3B82F6), true, () => _startTask(task.id)),
                  const SizedBox(height: 10),
                ],
                if (canSubmit)
                  _actionBtn(
                    _isSubmitting
                        ? 'Submitting…'
                        : task.adminReviewStatus == 'needs_revision'
                            ? 'Re-submit for Review'
                            : 'Submit for Review',
                    Icons.send_rounded,
                    AppTheme.accent,
                    false,
                    _isSubmitting ? null : () => _submitTask(task),
                    loading: _isSubmitting,
                  ),
                if (isSubmitted)
                  _banner('Submitted — waiting for admin review',
                      const Color(0xFF3B82F6),
                      icon: Icons.hourglass_top_rounded),
                if (isCompleted && task.adminReviewStatus == 'approved')
                  _banner('Task Approved & Completed! 🎉', AppTheme.accent,
                      icon: Icons.verified_rounded),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _linkTile(TaskSubmissionLink link) {
    final color = link.isGitHub
        ? const Color(0xFF24292F)
        : link.isLinkedIn
            ? const Color(0xFF0A66C2)
            : const Color(0xFF8B5CF6);
    final icon = link.isGitHub
        ? Icons.code_rounded
        : link.isLinkedIn
            ? Icons.work_outline_rounded
            : Icons.link_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(link.label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          Text(link.url,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
        IconButton(
          icon: const Icon(Icons.copy_rounded,
              size: 17, color: AppTheme.textLight),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: link.url));
            _showSnack('Copied!', AppTheme.accent);
          },
        ),
        IconButton(
          icon: Icon(Icons.open_in_new_rounded, size: 17, color: color),
          onPressed: () => _openUrl(link.url),
        ),
      ]),
    );
  }

  Widget _linkField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      required Color color}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 12),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 17),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }

  InputDecoration _inputDec(
          String label, String hint, IconData icon, Color color,
          {bool alignHint = false}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: alignHint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 12),
        prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: alignHint ? 60 : 0),
            child: Icon(icon, color: color, size: 20)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2)),
      );

  Widget _remarkCard(TaskModel task) {
    final isApproved = task.adminReviewStatus == 'approved';
    final isRevision = task.adminReviewStatus == 'needs_revision';
    final color = isApproved
        ? AppTheme.accent
        : isRevision
            ? Colors.orange
            : Colors.red;
    final icon = isApproved
        ? Icons.verified_rounded
        : isRevision
            ? Icons.edit_note_rounded
            : Icons.cancel_rounded;
    final label = isApproved
        ? 'Approved ✅'
        : isRevision
            ? 'Needs Revision 🔄'
            : 'Rejected ❌';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text('Admin Review — $label',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          if (task.reviewedAt != null)
            Text(DateFormat('MMM dd').format(task.reviewedAt!),
                style:
                    const TextStyle(color: AppTheme.textLight, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Text(task.adminRemark ?? '',
                style: const TextStyle(
                    color: AppTheme.textDark, fontSize: 14, height: 1.5))),
        if (isRevision) ...[
          const SizedBox(height: 10),
          const Text('Edit your submission and re-submit for review.',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, bool outlined,
      VoidCallback? onPressed,
      {bool loading = false}) {
    final content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (loading)
        const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
      else
        Icon(icon, size: 19),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    ]);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color, width: 1.5),
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: content)
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: content),
    );
  }

  Widget _banner(String msg, Color color, {IconData? icon}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8)
          ],
          Text(msg,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF2))),
        child: child,
      );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark));

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) =>
      Row(children: [
        Icon(icon, size: 16, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
        Flexible(
            child: Text(value,
                style: TextStyle(
                    color: color ?? AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ]);

  Widget _statusBadge(String status) {
    final map = {
      'pending': [const Color(0xFFFF6E40), 'Pending'],
      'in_progress': [const Color(0xFF3B82F6), 'In Progress'],
      'submitted': [const Color(0xFF8B5CF6), 'Submitted'],
      'completed': [AppTheme.accent, 'Completed'],
    };
    final item = map[status] ?? [AppTheme.textLight, status];
    final color = item[0] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(item[1] as String,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _priorityBadge(String p) {
    final c = {
          'high': Colors.red,
          'medium': Colors.orange,
          'low': Colors.green
        }[p] ??
        Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.flag_rounded, size: 12, color: c),
        const SizedBox(width: 4),
        Text(p.toUpperCase(),
            style:
                TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _categoryChip(String cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(cat,
            style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
}
