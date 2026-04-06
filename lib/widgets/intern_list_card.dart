// ─── lib/widgets/intern_list_card.dart ────────────────────────────────────

import 'package:flutter/material.dart';
import '../main.dart';
import '../models/intern_user.dart';

class InternListCard extends StatelessWidget {
  final InternUser intern;
  final VoidCallback? onTap;

  const InternListCard({super.key, required this.intern, this.onTap});

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
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: _avatarColor(intern.name).withOpacity(0.15),
              child: Text(
                intern.name.isNotEmpty ? intern.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _avatarColor(intern.name),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intern.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${intern.department} • ${intern.batchNo}',
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: intern.progressPercent,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _statusColor(intern.status)),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${intern.completedTasks}/${intern.totalTasks}',
                        style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(intern.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    intern.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(intern.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppTheme.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.accent;
      case 'completed':
        return const Color(0xFF3B82F6);
      default:
        return Colors.orange;
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      AppTheme.accent,
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      AppTheme.accentOrange,
      const Color(0xFFEC4899),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
