import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.forStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approv')) {
      return StatusBadge(
        label: 'Approved',
        foregroundColor: AppColors.statusApproved,
        backgroundColor: AppColors.statusApprovedBg,
        icon: Icons.check_circle_rounded,
      );
    } else if (lower.contains('review')) {
      return StatusBadge(
        label: 'In Review',
        foregroundColor: AppColors.statusInReview,
        backgroundColor: AppColors.statusInReviewBg,
        icon: Icons.timelapse_rounded,
      );
    } else if (lower.contains('reject')) {
      return StatusBadge(
        label: 'Rejected',
        foregroundColor: AppColors.statusRejected,
        backgroundColor: AppColors.statusRejectedBg,
        icon: Icons.cancel_rounded,
      );
    } else if (lower.contains('return')) {
      return StatusBadge(
        label: 'Returned',
        foregroundColor: AppColors.statusReturned,
        backgroundColor: AppColors.statusReturnedBg,
        icon: Icons.replay_rounded,
      );
    } else if (lower.contains('draft')) {
      return StatusBadge(
        label: 'Draft',
        foregroundColor: AppColors.statusDraft,
        backgroundColor: AppColors.statusDraftBg,
        icon: Icons.edit_note_rounded,
      );
    } else {
      // Default pending
      return StatusBadge(
        label: 'Pending',
        foregroundColor: AppColors.statusPending,
        backgroundColor: AppColors.statusPendingBg,
        icon: Icons.hourglass_top_rounded,
      );
    }
  }

  factory StatusBadge.forPriority(String priority) {
    final lower = priority.toLowerCase();
    Color color;
    if (lower.contains('urgent')) {
      color = AppColors.priorityUrgent;
    } else if (lower.contains('high')) {
      color = AppColors.priorityHigh;
    } else if (lower.contains('med')) {
      color = AppColors.priorityMedium;
    } else {
      color = AppColors.priorityLow;
    }

    return StatusBadge(
      label: priority.toUpperCase(),
      foregroundColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
      icon: Icons.flag_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDimensions.roundedSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
