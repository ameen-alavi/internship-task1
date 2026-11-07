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
import '../../../data/models/workflow_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workflow_provider.dart';

class RequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkflowProvider>().fetchRequestById(
        widget.requestId,
        viewer: context.read<AuthProvider>().currentUser,
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showApprovalDialog(
    BuildContext context,
    WorkflowRequest req,
    WorkflowStatus action,
  ) {
    final remarksController = TextEditingController();
    final isApproval =
        action == WorkflowStatus.approved || action == WorkflowStatus.inReview;
    final isRejection = action == WorkflowStatus.rejected;
    final isReturn = action == WorkflowStatus.returned;

    String actionTitle = 'Approve Workflow Stage';
    if (isRejection) actionTitle = 'Reject Application';
    if (isReturn) actionTitle = 'Return for Clarifications';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            actionTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to sign off on stage "${req.stages[req.currentStageIndex].title}".',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isApproval
                        ? 'Official Remarks / Notes (Optional)'
                        : 'Mandatory Reason for Action *',
                    hintText:
                        'Enter institutional remarks for the applicant...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRejection
                    ? AppColors.statusRejected
                    : (isReturn
                          ? AppColors.statusReturned
                          : AppColors.statusApproved),
              ),
              onPressed: () async {
                final remarks = remarksController.text.trim();
                if (!isApproval && remarks.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please provide an official justification remarks.',
                      ),
                    ),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                final provider = context.read<WorkflowProvider>();

                final success = await provider.updateRequestStatus(
                  requestId: req.id,
                  status: action,
                  remarks: remarks.isEmpty
                      ? 'Stage verified and endorsed.'
                      : remarks,
                  reviewer: auth.currentUser,
                );

                if (mounted && success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Application #${req.id} status updated to ${action.displayName}!',
                      ),
                      backgroundColor: AppColors.statusApproved,
                    ),
                  );
                }
              },
              child: Text(actionTitle),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitComment(WorkflowRequest req) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final provider = context.read<WorkflowProvider>();
    final ok = await provider.addComment(
      requestId: req.id,
      content: text,
      author: user,
    );
    if (ok) {
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final workflowProvider = context.watch<WorkflowProvider>();
    final authProvider = context.watch<AuthProvider>();

    final req = workflowProvider.selectedRequest;

    if (workflowProvider.isLoading && req == null) {
      return const LoadingIndicator(
        message: 'Loading request details & pipeline...',
      );
    }

    if (req == null) {
      return Scaffold(
        body: EmptyStateWidget(
          icon: Icons.find_in_page_outlined,
          title: 'Request Not Found',
          description:
              'The workflow petition with ID "${widget.requestId}" could not be located.',
          actionLabel: 'Return to Workflows',
          onActionPressed: () => context.go('/workflows'),
        ),
      );
    }

    final canPerformAction =
        workflowProvider.canReview(req, authProvider.currentUser) &&
        (req.status == WorkflowStatus.pending ||
            req.status == WorkflowStatus.inReview);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Back button & Action controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/workflows'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            req.id,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.forStatus(req.status.displayName),
                          const SizedBox(width: 8),
                          StatusBadge.forPriority(req.priority.displayName),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        req.title,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Approver Decision Alert Bar (if reviewer role is active)
            if (canPerformAction) ...[
              _buildApproverActionBanner(context, req: req, isDark: isDark),
              const SizedBox(height: AppDimensions.space24),
            ],

            // Main Body: 2 Columns on Desktop, Single Column on Mobile
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left (60%): Request metadata, description, attachments
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            _buildOverviewCard(
                              context,
                              req: req,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppDimensions.space20),
                            _buildMetadataCard(
                              context,
                              req: req,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space24),
                      // Right (40%): Multi-stage Approval Stepper & Discussion Comments
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildPipelineCard(
                              context,
                              req: req,
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppDimensions.space20),
                            _buildCommentsCard(
                              context,
                              req: req,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildPipelineCard(context, req: req, isDark: isDark),
                      const SizedBox(height: AppDimensions.space16),
                      _buildOverviewCard(context, req: req, isDark: isDark),
                      const SizedBox(height: AppDimensions.space16),
                      _buildMetadataCard(context, req: req, isDark: isDark),

                      const SizedBox(height: AppDimensions.space16),
                      _buildCommentsCard(context, req: req, isDark: isDark),
                    ],
                  ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildApproverActionBanner(
    BuildContext context, {
    required WorkflowRequest req,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: AppColors.statusApproved.withValues(alpha: 0.3),
        ),
        borderRadius: AppDimensions.roundedMedium,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusApproved.withValues(alpha: 0.15),
              borderRadius: AppDimensions.roundedSmall,
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              color: AppColors.statusApproved,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Department Action Required',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'You are authorized to review and approve Stage ${req.currentStageIndex + 1}: ${req.stages[req.currentStageIndex].title}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusReturned,
                ),
                onPressed: () =>
                    _showApprovalDialog(context, req, WorkflowStatus.returned),
                child: const Text('Return Changes'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusRejected,
                ),
                onPressed: () =>
                    _showApprovalDialog(context, req, WorkflowStatus.rejected),
                child: const Text('Reject'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusApproved,
                ),
                onPressed: () => _showApprovalDialog(
                  context,
                  req,
                  req.currentStageIndex + 1 == req.stages.length
                      ? WorkflowStatus.approved
                      : WorkflowStatus.inReview,
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Approve Stage'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required WorkflowRequest req,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APPLICATION SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Applicant Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    req.requesterName
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.requesterName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${req.department} • ${req.requesterEmail}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Submitted',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    Text(
                      DateFormatter.formatShortDate(req.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),

            // Description
            const Text(
              'Institutional Justification',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              req.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context, {
    required WorkflowRequest req,
    required bool isDark,
  }) {
    if (req.metadata.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CATEGORY SPECIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  req.category.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: req.metadata.entries.map((entry) {
                return SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key
                            .replaceAllMapped(
                              RegExp(r'([A-Z])'),
                              (m) => ' ${m.group(1)}',
                            )
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineCard(
    BuildContext context, {
    required WorkflowRequest req,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'APPROVAL PIPELINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${(req.progressPercentage * 100).toInt()}% Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Stepper
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: req.stages.length,
              itemBuilder: (context, index) {
                final stage = req.stages[index];
                final isLast = index == req.stages.length - 1;

                Color iconColor = isDark
                    ? AppColors.textMutedDark
                    : AppColors.borderLight;
                IconData iconData = Icons.circle_outlined;
                if (stage.status == StageStatus.approved) {
                  iconColor = AppColors.statusApproved;
                  iconData = Icons.check_circle_rounded;
                } else if (stage.status == StageStatus.inProgress) {
                  iconColor = AppColors.primaryLight;
                  iconData = Icons.radio_button_checked_rounded;
                } else if (stage.status == StageStatus.rejected) {
                  iconColor = AppColors.statusRejected;
                  iconData = Icons.cancel_rounded;
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Node & Line
                      Column(
                        children: [
                          Icon(iconData, color: iconColor, size: 20),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Stage Text Details
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stage.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  StatusBadge.forStatus(
                                    stage.status.displayName,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stage.approverRole}${stage.approverName != null ? ' • ${stage.approverName}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              if (stage.remarks != null &&
                                  stage.remarks!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF131D31)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: AppDimensions.roundedSmall,
                                  ),
                                  child: Text(
                                    'Remarks: "${stage.remarks}"',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              if (stage.updatedAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatDateTime(
                                    stage.updatedAt!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsCard(
    BuildContext context, {
    required WorkflowRequest req,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUDIT TRAIL & DISCUSSION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            if (req.comments.isEmpty)
              const Text(
                'No remarks or discussion yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: req.comments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cmt = req.comments[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF8FAFC),
                      borderRadius: AppDimensions.roundedMedium,
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cmt.authorName} (${cmt.authorRole})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormatter.formatRelative(cmt.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(cmt.content, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: AppDimensions.space16),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),

            // Post new message field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Type an institutional note or question...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _submitComment(req),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _submitComment(req),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
