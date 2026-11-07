import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/workflow_request_model.dart';
import '../../../providers/workflow_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/enquiry_provider.dart';
import '../../enquiries/widgets/enquiry_summary_card.dart';

class WorkflowListScreen extends StatefulWidget {
  const WorkflowListScreen({super.key});

  @override
  State<WorkflowListScreen> createState() => _WorkflowListScreenState();
}

class _WorkflowListScreenState extends State<WorkflowListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final workflowProvider = context.watch<WorkflowProvider>();
    final auth = context.watch<AuthProvider>();
    final enquiryProvider = context.watch<EnquiryProvider>();
    final enquiries = auth.isRequester
        ? enquiryProvider.enquiries
              .where(
                (e) =>
                    e.senderUserId == auth.currentUser?.id ||
                    e.senderEmail.toLowerCase() ==
                        auth.currentUser?.email.toLowerCase(),
              )
              .toList()
        : enquiryProvider.enquiries;
    final requests = auth.isRequester
        ? workflowProvider.requests
              .where((request) => request.requesterId == auth.currentUser?.id)
              .toList()
        : workflowProvider.requests
              .where((request) => request.requesterId != auth.currentUser?.id)
              .toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar: Title & New Application button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Institutional Workflows',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse, search and track all departmental requisitions and approval petitions',
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
                if (auth.isRequester)
                  AppButton(
                    label: isMobile ? 'New' : 'New Request',
                    icon: Icons.add_rounded,
                    onPressed: () => context.go('/workflows/new'),
                    variant: AppButtonVariant.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space20),

            // Search Bar & Filter Controls
            _buildFilterBar(
              context,
              workflowProvider,
              isDesktop: isDesktop,
              isDark: isDark,
            ),
            const SizedBox(height: AppDimensions.space16),

            // Status Filter Chips
            _buildStatusFilterChips(context, workflowProvider, isDark: isDark),
            const SizedBox(height: AppDimensions.space20),

            // Content Area (Table or Cards or Empty State)
            if (workflowProvider.isLoading && requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingIndicator(message: 'Filtering workflows...'),
              )
            else if (requests.isEmpty)
              EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'No Workflows Found',
                description:
                    'No applications match your active search and filter parameters.',
                actionLabel: 'Reset All Filters',
                onActionPressed: () {
                  _searchController.clear();
                  workflowProvider.clearFilters();
                },
              )
            else if (isDesktop)
              _buildDesktopTable(context, requests: requests, isDark: isDark)
            else
              _buildMobileCardList(context, requests: requests, isDark: isDark),

            if (enquiries.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space24),
              Text('Enquiries', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.space12),
              ...enquiries.map(
                (e) => EnquirySummaryCard(enquiry: e, isDark: isDark),
              ),
            ],
            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WorkflowProvider provider, {
    required bool isDesktop,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => provider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText:
                            'Search by title, ID, applicant or keyword...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<WorkflowCategory?>(
                      initialValue: provider.categoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...WorkflowCategory.values.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                        ),
                      ],
                      onChanged: (cat) => provider.setCategoryFilter(cat),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PriorityLevel?>(
                      initialValue: provider.priorityFilter,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Priorities'),
                        ),
                        ...PriorityLevel.values.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ),
                        ),
                      ],
                      onChanged: (p) => provider.setPriorityFilter(p),
                    ),
                  ),
                  if (provider.searchQuery.isNotEmpty ||
                      provider.categoryFilter != null ||
                      provider.statusFilter != null ||
                      provider.priorityFilter != null) ...[
                    const SizedBox(width: AppDimensions.space12),
                    IconButton(
                      tooltip: 'Clear Filters',
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearFilters();
                      },
                    ),
                  ],
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => provider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search workflows...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<WorkflowCategory?>(
                          initialValue: provider.categoryFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Categories',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            ...WorkflowCategory.values.map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c.shortName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (cat) => provider.setCategoryFilter(cat),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<PriorityLevel?>(
                          initialValue: provider.priorityFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Priorities',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            ...PriorityLevel.values.map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (p) => provider.setPriorityFilter(p),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusFilterChips(
    BuildContext context,
    WorkflowProvider provider, {
    required bool isDark,
  }) {
    final statuses = [
      null,
      WorkflowStatus.pending,
      WorkflowStatus.inReview,
      WorkflowStatus.approved,
      WorkflowStatus.rejected,
      WorkflowStatus.returned,
      WorkflowStatus.draft,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = provider.statusFilter == status;
          final label = status == null ? 'All Statuses' : status.displayName;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(label),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
              ),
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              selectedColor: isDark
                  ? AppColors.primaryLight
                  : AppColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.roundedSmall,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              onSelected: (_) => provider.setStatusFilter(status),
            ),
          );
        }).toList(),
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
                  child: Text('WORKFLOW ID', style: _headerStyle),
                ),
                Expanded(
                  flex: 4,
                  child: Text('TITLE & CATEGORY', style: _headerStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('APPLICANT / DEPT', style: _headerStyle),
                ),
                Expanded(flex: 2, child: Text('PRIORITY', style: _headerStyle)),
                Expanded(
                  flex: 3,
                  child: Text('CURRENT STAGE & PROGRESS', style: _headerStyle),
                ),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                Expanded(flex: 2, child: Text('UPDATED', style: _headerStyle)),
                SizedBox(width: 40),
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
                      // Applicant
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
                      // Stage & Progress
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.stages[req.currentStageIndex].title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      // Updated At
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormatter.formatRelative(req.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                        child: Icon(Icons.chevron_right, size: 20),
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
                  const SizedBox(height: 6),
                  Text(
                    '${req.requesterName} • ${req.department}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  const Divider(height: 1),
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      StatusBadge.forPriority(req.priority.displayName),
                      const Spacer(),
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
                  const SizedBox(height: 8),
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

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondaryLight,
    letterSpacing: 0.5,
  );
}
