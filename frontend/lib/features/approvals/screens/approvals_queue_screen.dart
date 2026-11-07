import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/workflow_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workflow_provider.dart';

class ApprovalsQueueScreen extends StatelessWidget {
  const ApprovalsQueueScreen({super.key});

  void _showQuickDecisionDialog(
    BuildContext context,
    WorkflowRequest req,
    bool isApprove,
  ) {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isApprove ? 'Confirm Approval' : 'Reject Application',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request: #${req.id} — "${req.title}"',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Applicant: ${req.requesterName} (${req.department})',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                labelText: isApprove
                    ? 'Official Remarks (Optional)'
                    : 'Rejection Reason *',
                hintText: isApprove
                    ? 'e.g. Endorsed by department.'
                    : 'Reason for rejection...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? AppColors.statusApproved
                  : AppColors.statusRejected,
            ),
            onPressed: () async {
              final remarks = remarksController.text.trim();
              if (!isApprove && remarks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rejection reason is required.'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final provider = context.read<WorkflowProvider>();

              final success = await provider.updateRequestStatus(
                requestId: req.id,
                status: isApprove
                    ? (req.currentStageIndex + 1 == req.stages.length
                          ? WorkflowStatus.approved
                          : WorkflowStatus.inReview)
                    : WorkflowStatus.rejected,
                remarks: remarks.isEmpty
                    ? 'Endorsed in batch review.'
                    : remarks,
                reviewer: auth.currentUser,
              );

              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isApprove ? 'Approved #${req.id}' : 'Rejected #${req.id}',
                    ),
                    backgroundColor: isApprove
                        ? AppColors.statusApproved
                        : AppColors.statusRejected,
                  ),
                );
              }
            },
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final authProvider = context.watch<AuthProvider>();
    final workflowProvider = context.watch<WorkflowProvider>();
    final pendingList = workflowProvider.pendingApprovals
        .where(
          (request) =>
              workflowProvider.canReview(request, authProvider.currentUser),
        )
        .toList();
    final isRequester = authProvider.isRequester;

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
                        'Departmental Approval Queue',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review incoming requisitions and multi-stage petitions awaiting signature',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusPendingBg,
                    borderRadius: AppDimensions.roundedSmall,
                  ),
                  child: Text(
                    '${pendingList.length} PENDING ITEMS',
                    style: const TextStyle(
                      color: AppColors.statusPending,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Demo Role Helper Banner if user is currently Requester
            if (isRequester) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                  borderRadius: AppDimensions.roundedMedium,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are currently signed in as Requester (User)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Switch your persona to "Approver (Dr. K. R. Sharma)" to test signing off on approval queues.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Switch to Approver',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            if (workflowProvider.isLoading && pendingList.isEmpty)
              const LoadingIndicator(message: 'Checking approval queue...')
            else if (pendingList.isEmpty)
              EmptyStateWidget(
                icon: Icons.task_alt_rounded,
                title: 'Queue is Clear',
                description:
                    'There are no pending requisitions awaiting your departmental review at this time.',
                actionLabel: 'View All Workflows',
                onActionPressed: () => context.go('/workflows'),
              )
            else if (isDesktop)
              _buildDesktopApprovalsTable(
                context,
                list: pendingList,
                isDark: isDark,
              )
            else
              _buildMobileApprovalsList(
                context,
                list: pendingList,
                isDark: isDark,
              ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopApprovalsTable(
    BuildContext context, {
    required List<WorkflowRequest> list,
    required bool isDark,
  }) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2333) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMedium),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('REQUEST ID', style: _hStyle)),
                Expanded(
                  flex: 4,
                  child: Text('PETITION & CATEGORY', style: _hStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('APPLICANT & DEPT', style: _hStyle),
                ),
                Expanded(flex: 2, child: Text('PRIORITY', style: _hStyle)),
                Expanded(
                  flex: 3,
                  child: Text('CURRENT REVIEW STAGE', style: _hStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ACTIONS',
                    style: _hStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final req = list[index];
              return InkWell(
                onTap: () => context.go('/workflows/${req.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          req.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              req.category.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.requesterName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              req.department,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge.forPriority(
                            req.priority.displayName,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.stages[req.currentStageIndex].title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Submitted ${DateFormatter.formatRelative(req.createdAt)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Reject',
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: AppColors.statusRejected,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _showQuickDecisionDialog(context, req, false),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusApproved,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () =>
                                  _showQuickDecisionDialog(context, req, true),
                              child: const Text(
                                'Approve',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileApprovalsList(
    BuildContext context, {
    required List<WorkflowRequest> list,
    required bool isDark,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) {
        final req = list[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    StatusBadge.forPriority(req.priority.displayName),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  req.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${req.requesterName} • ${req.department}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Stage: ${req.stages[req.currentStageIndex].title}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => context.go('/workflows/${req.id}'),
                      child: const Text(
                        'Details',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusRejected,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () =>
                          _showQuickDecisionDialog(context, req, false),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusApproved,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () =>
                          _showQuickDecisionDialog(context, req, true),
                      child: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _hStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.5,
  );
}
