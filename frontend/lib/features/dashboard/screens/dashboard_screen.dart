import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/workflow_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workflow_provider.dart';
import '../../../providers/enquiry_provider.dart';
import '../../enquiries/widgets/enquiry_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final authProvider = context.watch<AuthProvider>();
    final workflowProvider = context.watch<WorkflowProvider>();
    final enquiryProvider = context.watch<EnquiryProvider>();
    final user = authProvider.currentUser;

    if (workflowProvider.isLoading && workflowProvider.requests.isEmpty) {
      return const LoadingIndicator(
        message: 'Loading institutional dashboard...',
      );
    }

    final visibleRequests = authProvider.isRequester
        ? workflowProvider.requests
              .where((request) => request.requesterId == user?.id)
              .toList()
        : workflowProvider.requests
              .where((request) => request.requesterId != user?.id)
              .toList();
    final stats = <String, int>{
      'total': visibleRequests.length,
      'pending': visibleRequests
          .where(
            (request) =>
                request.status == WorkflowStatus.pending ||
                request.status == WorkflowStatus.inReview,
          )
          .length,
      'approved': visibleRequests
          .where((request) => request.status == WorkflowStatus.approved)
          .length,
      'rejected': visibleRequests
          .where(
            (request) =>
                request.status == WorkflowStatus.rejected ||
                request.status == WorkflowStatus.returned,
          )
          .length,
    };
    final recentRequests = (List<WorkflowRequest>.from(
      visibleRequests,
    )..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).take(5).toList();
    final pendingCount = authProvider.isApprover
        ? workflowProvider.pendingApprovals
              .where((request) => request.requesterId != user?.id)
              .length
        : stats['pending']!;

    return RefreshIndicator(
      onRefresh: () async {
        await workflowProvider.fetchRequests();
        await workflowProvider.fetchStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Quick Action
            _buildWelcomeBanner(
              context,
              user: user,
              canCreate: authProvider.isRequester,
              isDesktop: isDesktop,
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space24),

            // Pending Approvals Alert Banner (if any)
            if (pendingCount > 0 && authProvider.isApprover) ...[
              _buildPendingActionBanner(
                context,
                pendingCount: pendingCount,
                isDark: isDark,
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            // 4 Metrics Cards Grid
            _buildMetricsGrid(
              context,
              stats: stats,
              isDesktop: isDesktop,
              isMobile: isMobile,
            ),
            const SizedBox(height: AppDimensions.space32),

            // Quick Request Categories
            if (authProvider.isRequester)
              _buildQuickActionCards(
                context,
                isDesktop: isDesktop,
                isDark: isDark,
              ),
            const SizedBox(height: AppDimensions.space32),

            // Recent Institutional Workflows Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Workflow Applications',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time status tracking and multi-tier stage progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/workflows'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            if (recentRequests.isEmpty)
              EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'No Workflow Applications',
                description: authProvider.isRequester
                    ? 'You have not submitted any workflow applications yet.'
                    : 'There are no requests assigned to your review role.',
                actionLabel: authProvider.isRequester
                    ? 'Create First Request'
                    : null,
                onActionPressed: authProvider.isRequester
                    ? () => context.go('/workflows/new')
                    : null,
              )
            else if (isDesktop)
              _buildDesktopTable(
                context,
                requests: recentRequests,
                isDark: isDark,
              )
            else
              _buildMobileCardList(
                context,
                requests: recentRequests,
                isDark: isDark,
              ),

            if (enquiryProvider.enquiries.any(
              (e) =>
                  authProvider.isApprover ||
                  e.senderUserId == user?.id ||
                  e.senderEmail.toLowerCase() == user?.email.toLowerCase(),
            )) ...[
              const SizedBox(height: AppDimensions.space24),
              Text(
                'Recent Enquiries',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...enquiryProvider.recentEnquiries
                  .where(
                    (e) =>
                        authProvider.isApprover ||
                        e.senderUserId == user?.id ||
                        e.senderEmail.toLowerCase() ==
                            user?.email.toLowerCase(),
                  )
                  .map((e) => EnquirySummaryCard(enquiry: e, isDark: isDark)),
            ],

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context, {
    required User? user,
    required bool canCreate,
    required bool isDesktop,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isDesktop ? AppDimensions.space24 : AppDimensions.space20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDimensions.roundedLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppDimensions.roundedSmall,
                  ),
                  child: Text(
                    user?.role.displayName ?? 'Institutional Member',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  'Welcome, ${user?.name ?? 'Faculty & Student Portal'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 24 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  '${user?.department ?? 'EduSphere Institute'} • ${user?.designation ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop && canCreate) ...[
            const SizedBox(width: AppDimensions.space24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onPressed: () => context.go('/workflows/new'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('New Request'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingActionBanner(
    BuildContext context, {
    required int pendingCount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        border: Border.all(
          color: AppColors.statusPending.withValues(alpha: 0.4),
        ),
        borderRadius: AppDimensions.roundedMedium,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusPending,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have $pendingCount workflow item${pendingCount > 1 ? 's' : ''} awaiting your departmental review & approval.',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go('/approvals'),
            child: const Text(
              'Go to Queue →',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, {
    required Map<String, int> stats,
    required bool isDesktop,
    required bool isMobile,
  }) {
    final cards = [
      StatCard(
        title: 'Total Applications',
        value: '${stats['total'] ?? 0}',
        subtitle: 'All-time submissions',
        icon: Icons.all_inbox_rounded,
        accentColor: AppColors.primaryLight,
        onTap: () => context.go('/workflows'),
      ),
      StatCard(
        title: 'In Progress / Pending',
        value: '${stats['pending'] ?? 0}',
        subtitle: 'Awaiting stage sign-off',
        icon: Icons.pending_actions_rounded,
        accentColor: AppColors.statusPending,
        onTap: () => context.go('/workflows'),
      ),
      StatCard(
        title: 'Approved Workflows',
        value: '${stats['approved'] ?? 0}',
        subtitle: 'Signatures finalized',
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppColors.statusApproved,
        onTap: () => context.go('/workflows'),
      ),
      StatCard(
        title: 'Needs Revision / Rejected',
        value: '${stats['rejected'] ?? 0}',
        subtitle: 'Returned with remarks',
        icon: Icons.error_outline_rounded,
        accentColor: AppColors.statusRejected,
        onTap: () => context.go('/workflows'),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppDimensions.space12,
          mainAxisSpacing: AppDimensions.space12,
          childAspectRatio: isMobile ? 1.25 : 1.6,
          children: cards,
        );
      },
    );
  }

  Widget _buildQuickActionCards(
    BuildContext context, {
    required bool isDesktop,
    required bool isDark,
  }) {
    final actions = [
      _QuickActionItem(
        title: 'Leave Application',
        subtitle: 'Duty, Medical & Personal Leave',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF0284C7),
        category: WorkflowCategory.leave,
      ),
      _QuickActionItem(
        title: 'Bonafide / NOC',
        subtitle: 'Certificates & Visas',
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF059669),
        category: WorkflowCategory.certificate,
      ),
      _QuickActionItem(
        title: 'Budget & Equipment',
        subtitle: 'Lab Resources & Grants',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7C3AED),
        category: WorkflowCategory.requisition,
      ),
      _QuickActionItem(
        title: 'Research Clearance',
        subtitle: 'IRB Ethics & Projects',
        icon: Icons.science_outlined,
        color: const Color(0xFFD97706),
        category: WorkflowCategory.clearance,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Workflow Requisitions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.space12),
        isDesktop
            ? Row(
                children: actions
                    .map(
                      (item) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildActionTile(context, item, isDark),
                        ),
                      ),
                    )
                    .toList(),
              )
            : GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: actions
                    .map((item) => _buildActionTile(context, item, isDark))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    _QuickActionItem item,
    bool isDark,
  ) {
    return Card(
      child: InkWell(
        onTap: () =>
            context.go('/workflows/new?category=${item.category.name}'),
        borderRadius: AppDimensions.roundedMedium,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: AppDimensions.roundedSmall,
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
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
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context, {
    required List<WorkflowRequest> requests,
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
                Expanded(
                  flex: 2,
                  child: Text('WORKFLOW ID', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 4,
                  child: Text('TITLE & CATEGORY', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('APPLICANT / DEPT', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('PRIORITY', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('PROGRESS / STAGE', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text('STATUS', style: _tableHeaderStyle),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'ACTION',
                    style: _tableHeaderStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final req = requests[index];
              final progress = req.progressPercentage;

              return InkWell(
                onTap: () => context.go('/workflows/${req.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // ID
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
                      // Title & Category
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
                      // Applicant & Dept
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
                      // Priority
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge.forPriority(
                            req.priority.displayName,
                          ),
                        ),
                      ),
                      // Progress Bar & Stage
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Stage ${req.currentStageIndex + 1} of ${req.stages.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: AppDimensions.roundedFull,
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    req.status == WorkflowStatus.approved
                                        ? AppColors.statusApproved
                                        : AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Status
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge.forStatus(req.status.displayName),
                        ),
                      ),
                      // Action
                      SizedBox(
                        width: 80,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                            onPressed: () => context.go('/workflows/${req.id}'),
                          ),
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

  Widget _buildMobileCardList(
    BuildContext context, {
    required List<WorkflowRequest> requests,
    required bool isDark,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) {
        final req = requests[index];
        final progress = req.progressPercentage;

        return Card(
          child: InkWell(
            onTap: () => context.go('/workflows/${req.id}'),
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
                        req.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      StatusBadge.forStatus(req.status.displayName),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    req.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        req.category.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      StatusBadge.forPriority(req.priority.displayName),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  const Divider(height: 1),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stage ${req.currentStageIndex + 1}/${req.stages.length}: ${req.stages[req.currentStageIndex].title}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormatter.formatRelative(req.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppDimensions.roundedFull,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        req.status == WorkflowStatus.approved
                            ? AppColors.statusApproved
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.5,
  );
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WorkflowCategory category;

  _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
  });
}
