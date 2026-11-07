import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/enquiry_model.dart';

/// Compact enquiry card used in enquiry lists and workflow activity sections.
class EnquirySummaryCard extends StatelessWidget {
  final Enquiry enquiry;
  final bool isDark;

  const EnquirySummaryCard({
    super.key,
    required this.enquiry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final e = enquiry;
    return Card(
      child: InkWell(
        onTap: () => context.go('/enquiries/${e.id}'),
        borderRadius: AppDimensions.roundedMedium,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  StatusBadge(
                    label: e.status.displayName,
                    foregroundColor: e.status.color,
                    backgroundColor: e.status.backgroundColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                e.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${e.senderName} • ${e.department}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusBadge.forPriority(e.priority.displayName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.category.shortName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatRelative(e.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
