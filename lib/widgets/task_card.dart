// ─── lib/widgets/task_card.dart ───────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isIntern;
  final bool showAssignee;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.isIntern,
    this.showAssignee = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRemark = task.hasReview;
    final remarkColor = _remarkColor(task.adminReviewStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRemark
                ? remarkColor.withOpacity(0.35)
                : _statusColor(task.status).withOpacity(0.2),
            width: hasRemark ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority bar
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showAssignee)
                        Text(
                          '→ ${task.assignedToName}',
                          style: const TextStyle(
                              color: AppTheme.textLight, fontSize: 12),
                        ),
                      if (!showAssignee && task.category.isNotEmpty)
                        Text(
                          task.category,
                          style: const TextStyle(
                              color: AppTheme.textLight, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                _statusChip(task.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: const TextStyle(
                color: AppTheme.textMid,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // ── Bottom row ──
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: task.isOverdue ? Colors.red : AppTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due ${DateFormat('MMM dd').format(task.dueDate)}',
                  style: TextStyle(
                    color:
                        task.isOverdue ? Colors.red : AppTheme.textLight,
                    fontSize: 11,
                    fontWeight: task.isOverdue
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (task.attachments.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.attach_file_rounded,
                      size: 13, color: AppTheme.textLight),
                  Text(' ${task.attachments.length}',
                      style: const TextStyle(
                          color: AppTheme.textLight, fontSize: 11)),
                ],
                const Spacer(),
                // Admin remark badge
                if (hasRemark)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: remarkColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_remarkIcon(task.adminReviewStatus),
                          size: 11, color: remarkColor),
                      const SizedBox(width: 3),
                      Text(
                        _remarkLabel(task.adminReviewStatus),
                        style: TextStyle(
                            color: remarkColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                if (isIntern) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppTheme.textLight),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':        return AppTheme.accentOrange;
      case 'in_progress':   return const Color(0xFF3B82F6);
      case 'submitted':     return const Color(0xFF8B5CF6);
      case 'completed':     return AppTheme.accent;
      default:              return AppTheme.textLight;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':   return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':    return Colors.green;
      default:       return AppTheme.textLight;
    }
  }

  Color _remarkColor(String? s) {
    switch (s) {
      case 'approved':       return AppTheme.accent;
      case 'needs_revision': return Colors.orange;
      case 'rejected':       return Colors.red;
      default:               return AppTheme.textLight;
    }
  }

  IconData _remarkIcon(String? s) {
    switch (s) {
      case 'approved':       return Icons.verified_rounded;
      case 'needs_revision': return Icons.edit_note_rounded;
      case 'rejected':       return Icons.cancel_rounded;
      default:               return Icons.rate_review_rounded;
    }
  }

  String _remarkLabel(String? s) {
    switch (s) {
      case 'approved':       return 'Approved';
      case 'needs_revision': return 'Revise';
      case 'rejected':       return 'Rejected';
      default:               return '';
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    final labels = {
      'pending':     'Pending',
      'in_progress': 'Active',
      'submitted':   'Submitted',
      'completed':   'Done',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
