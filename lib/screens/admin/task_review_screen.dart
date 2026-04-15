// ─── lib/screens/admin/task_review_screen.dart ────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../models/task_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/responsive.dart';

class TaskReviewScreen extends StatefulWidget {
  final String taskId;
  const TaskReviewScreen({super.key, required this.taskId});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  final _remarkCtrl = TextEditingController();
  final _db = FirestoreService();
  bool _isSubmitting = false;
  String _reviewStatus = 'approved';

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview(TaskModel task) async {
    if (_remarkCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a remark before submitting.', Colors.red);
      return;
    }
    setState(() => _isSubmitting = true);
    await _db.reviewTask(
      taskId: task.id,
      internUid: task.assignedTo,
      reviewStatus: _reviewStatus,
      remark: _remarkCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final labels = {
      'approved': '✅ Task Approved!',
      'needs_revision': '🔄 Sent back for revision.',
      'rejected': '❌ Task Rejected.',
    };
    _showSnack(labels[_reviewStatus] ?? 'Review submitted.', AppTheme.accent);
    Navigator.pop(context);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final gapSize = isMobile ? 12.0 : 16.0;
    final hPad = ResponsiveHelper.paddingSymmetric(
      context,
      mobileH: 16,
      mobileV: 0,
      tabletH: 24,
      desktopH: 32,
    ).horizontal;
    final df = DateFormat('MMM dd, yyyy • hh:mm a');

    return StreamBuilder<TaskModel?>(
      stream: _db.streamTask(widget.taskId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final task = snap.data!;
        final alreadyReviewed = task.adminRemark != null &&
            task.adminRemark!.isNotEmpty &&
            task.status != 'submitted';

        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: ResponsiveText(
              'Review Submission',
              mobileSize: 16,
              tabletSize: 18,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              if (alreadyReviewed)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ResponsiveText(
                    'Reviewed',
                    mobileSize: 11,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Task Info Banner ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF1A3A5C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _statusChip(task.status),
                        const SizedBox(width: 8),
                        _priorityChip(task.priority),
                      ]),
                      const SizedBox(height: 12),
                      Text(task.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            color: Colors.white54, size: 15),
                        const SizedBox(width: 4),
                        Text(task.assignedToName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.white54, size: 15),
                        const SizedBox(width: 4),
                        Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Task Description ──
                _sectionLabel('📋  Task Description'),
                const SizedBox(height: 8),
                _card(
                  child: Text(task.description,
                      style: const TextStyle(
                          color: AppTheme.textMid, fontSize: 14, height: 1.6)),
                ),
                const SizedBox(height: 20),

                // ── Submission Details ──
                if (task.submittedAt != null) ...[
                  _sectionLabel('📤  Submission Details'),
                  const SizedBox(height: 8),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.schedule_rounded, 'Submitted At',
                            df.format(task.submittedAt!)),
                        if (task.submissionNote != null &&
                            task.submissionNote!.isNotEmpty) ...[
                          const Divider(height: 18),
                          const Text('Intern\'s Note:',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(task.submissionNote!,
                              style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 14,
                                  height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Submitted Links ──
                if (task.links.isNotEmpty) ...[
                  _sectionLabel('🔗  Submitted Links (${task.links.length})'),
                  const SizedBox(height: 8),
                  ...task.links.map((l) => _linkTile(l)),
                  const SizedBox(height: 16),
                ] else if (task.status == 'submitted') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('No links attached — text note only.',
                          style: TextStyle(color: Colors.orange, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Previous Review (if re-submitted) ──
                if (alreadyReviewed) ...[
                  _sectionLabel('📝  Previous Review'),
                  const SizedBox(height: 8),
                  _previousReviewCard(task),
                  const SizedBox(height: 20),
                ],

                // ── Review Form ──
                if (task.status == 'submitted') ...[
                  _sectionLabel('✍️  Your Review'),
                  SizedBox(height: gapSize),

                  // Review status selector
                  Wrap(
                    spacing: gapSize,
                    runSpacing: gapSize,
                    children: [
                      Expanded(
                          child: _reviewOption(
                              'approved', '✅ Approve', AppTheme.accent)),
                      Expanded(
                          child: _reviewOption(
                              'needs_revision', '🔄 Revise', Colors.orange)),
                      Expanded(
                          child: _reviewOption(
                              'rejected', '❌ Reject', Colors.red)),
                    ],
                  ),
                  SizedBox(height: gapSize * 1.5),

                  // Remark text field
                  TextField(
                    controller: _remarkCtrl,
                    maxLines: isMobile ? 4 : 5,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.fontSize(context,
                          mobileSize: 13, tabletSize: 14),
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: _remarkHint(_reviewStatus),
                      hintStyle: TextStyle(
                        fontSize: ResponsiveHelper.fontSize(context,
                            mobileSize: 12, tabletSize: 13),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.accent, width: 2)),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.paddingSymmetric(context,
                                mobileH: 14, mobileV: 0, tabletH: 16)
                            .horizontal,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: gapSize * 2),

                  // Submit Review Button
                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 48 : 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSubmitting ? null : () => _submitReview(task),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Icon(_reviewIcon(_reviewStatus)),
                      label: ResponsiveText(
                        _isSubmitting ? 'Submitting…' : 'Submit Review',
                        mobileSize: 14,
                        tabletSize: 15,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _reviewColor(_reviewStatus),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ] else if (!alreadyReviewed) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.paddingSymmetric(context,
                              mobileH: 16, mobileV: 0, tabletH: 20)
                          .horizontal,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: ResponsiveText(
                        'Waiting for intern to submit this task.',
                        mobileSize: 13,
                        tabletSize: 14,
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reviewOption(String value, String label, Color color) {
    final selected = _reviewStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _reviewStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: ResponsiveText(label,
            textAlign: TextAlign.center,
            mobileSize: 11,
            tabletSize: 12,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  Widget _previousReviewCard(TaskModel task) {
    final color = _reviewColor(task.adminReviewStatus ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_reviewIcon(task.adminReviewStatus ?? ''),
                color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              _reviewLabel(task.adminReviewStatus ?? ''),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Spacer(),
            if (task.reviewedAt != null)
              Text(
                DateFormat('MMM dd, yyyy').format(task.reviewedAt!),
                style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
              ),
          ]),
          const SizedBox(height: 10),
          Text(task.adminRemark ?? '',
              style: const TextStyle(
                  color: AppTheme.textDark, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _linkTile(TaskSubmissionLink link) {
    final isGh = link.isGitHub;
    final isLi = link.isLinkedIn;
    final color = isGh
        ? const Color(0xFF24292F)
        : isLi
            ? const Color(0xFF0A66C2)
            : const Color(0xFF8B5CF6);
    final icon = isGh
        ? Icons.code_rounded
        : isLi
            ? Icons.work_outline_rounded
            : Icons.link_rounded;
    final badge = isGh
        ? 'GitHub'
        : isLi
            ? 'LinkedIn'
            : 'Link';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(link.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13, color: color)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(badge,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(link.url,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final url = link.url.trim().startsWith('http')
                ? link.url.trim()
                : 'https://${link.url.trim()}';
            try {
              final uri = Uri.parse(url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              // fallback: try platformDefault mode
              try {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.platformDefault);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Cannot open: $url'),
                  backgroundColor: Colors.red,
                ));
              }
            }
          },
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text('Open'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark));

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 16, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
        Flexible(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ]);

  Widget _statusChip(String status) {
    final map = {
      'submitted': [const Color(0xFF8B5CF6), 'Submitted'],
      'completed': [AppTheme.accent, 'Completed'],
      'in_progress': [const Color(0xFF3B82F6), 'In Progress'],
      'pending': [const Color(0xFFFF6B35), 'Pending'],
    };
    final item = map[status] ?? [AppTheme.textLight, status];
    final color = item[0] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Text(item[1] as String,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _priorityChip(String p) {
    final colors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.green
    };
    final c = colors[p] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(p.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Color _reviewColor(String s) {
    switch (s) {
      case 'approved':
        return AppTheme.accent;
      case 'needs_revision':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return AppTheme.accent;
    }
  }

  IconData _reviewIcon(String s) {
    switch (s) {
      case 'approved':
        return Icons.verified_rounded;
      case 'needs_revision':
        return Icons.edit_note_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.rate_review_rounded;
    }
  }

  String _reviewLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Approved';
      case 'needs_revision':
        return 'Needs Revision';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  String _remarkHint(String s) {
    switch (s) {
      case 'approved':
        return 'Great work! Write encouragement or praise…';
      case 'needs_revision':
        return 'Explain what needs to be changed or improved…';
      case 'rejected':
        return 'Explain why this task is being rejected…';
      default:
        return 'Write your remarks here…';
    }
  }
}
