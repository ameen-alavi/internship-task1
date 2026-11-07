import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _filterOnlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveHelper.isMobile(context);

    final provider = context.watch<NotificationProvider>();
    final notifications = _filterOnlyUnread
        ? provider.notifications.where((n) => !n.isRead).toList()
        : provider.notifications;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Institutional Notifications',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time alerts, approval status updates, and departmental notices',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.unreadCount > 0)
                  TextButton.icon(
                    onPressed: () => provider.markAllAsRead(),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark all read'),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),

            // Filter Tabs
            Row(
              children: [
                ChoiceChip(
                  selected: !_filterOnlyUnread,
                  label: Text('All (${provider.notifications.length})'),
                  onSelected: (val) =>
                      setState(() => _filterOnlyUnread = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selected: _filterOnlyUnread,
                  label: Text('Unread (${provider.unreadCount})'),
                  onSelected: (val) => setState(() => _filterOnlyUnread = true),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),

            if (provider.isLoading && notifications.isEmpty)
              const LoadingIndicator(message: 'Loading notifications...')
            else if (notifications.isEmpty)
              EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: _filterOnlyUnread
                    ? 'No Unread Alerts'
                    : 'No Notifications',
                description: _filterOnlyUnread
                    ? 'You are all caught up! There are no unread institutional alerts.'
                    : 'Your notification inbox is currently empty.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ntf = notifications[index];

                  Color iconColor = AppColors.primaryLight;
                  IconData icon = Icons.info_outline_rounded;
                  if (ntf.type == NotificationType.workflowApproved) {
                    iconColor = AppColors.statusApproved;
                    icon = Icons.check_circle_outline_rounded;
                  } else if (ntf.type == NotificationType.workflowRejected) {
                    iconColor = AppColors.statusRejected;
                    icon = Icons.cancel_outlined;
                  } else if (ntf.type == NotificationType.workflowReturned) {
                    iconColor = AppColors.statusReturned;
                    icon = Icons.replay_circle_filled_rounded;
                  } else if (ntf.type == NotificationType.approvalRequired) {
                    iconColor = AppColors.statusPending;
                    icon = Icons.pending_actions_rounded;
                  }

                  return Card(
                    color: ntf.isRead
                        ? (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight)
                        : (isDark
                              ? const Color(0xFF131D31)
                              : const Color(0xFFEFF6FF)),
                    child: InkWell(
                      onTap: () {
                        provider.markAsRead(ntf.id);
                        if (ntf.relatedEnquiryId != null) {
                          context.go('/enquiries/${ntf.relatedEnquiryId}');
                        } else if (ntf.relatedRequestId != null) {
                          context.go('/workflows/${ntf.relatedRequestId}');
                        }
                      },
                      borderRadius: AppDimensions.roundedMedium,
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ntf.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: ntf.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.formatRelative(
                                          ntf.createdAt,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ntf.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (ntf.relatedRequestId != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Related: #${ntf.relatedRequestId}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 12,
                                          color: AppColors.primaryLight,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!ntf.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}
