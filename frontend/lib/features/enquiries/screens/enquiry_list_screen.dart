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
import '../../../data/models/enquiry_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/enquiry_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/enquiry_pagination_bar.dart';
import '../widgets/enquiry_summary_card.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
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

    final enquiryProvider = context.watch<EnquiryProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final isRequester = user?.role != UserRole.approver;
    final enquiries = user == null || user.role == UserRole.approver
        ? enquiryProvider.enquiries
        : enquiryProvider.enquiries
              .where(
                (enquiry) =>
                    enquiry.senderUserId == user.id ||
                    enquiry.senderEmail.toLowerCase() ==
                        user.email.toLowerCase(),
              )
              .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await enquiryProvider.fetchEnquiries();
          await enquiryProvider.fetchStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            isMobile ? AppDimensions.space16 : AppDimensions.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Action Bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Institutional Enquiries',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage admissions, academic, financial, and facilities enquiries with full lifecycle tracking',
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
                  if (isRequester)
                    AppButton(
                      label: isMobile ? 'New' : 'New Enquiry',
                      icon: Icons.add_rounded,
                      onPressed: () => context.go('/enquiries/new'),
                      variant: AppButtonVariant.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // Filter & Search Controls
              _buildFilterCard(
                context,
                enquiryProvider,
                isDesktop: isDesktop,
                isDark: isDark,
              ),
              const SizedBox(height: AppDimensions.space16),

              // Status Filter Chips
              if (isRequester)
                _buildStatusChips(context, enquiryProvider, isDark: isDark),
              const SizedBox(height: AppDimensions.space20),

              // Error State with Retry Button
              if (enquiryProvider.hasError) ...[
                _buildErrorCard(context, enquiryProvider, isDark: isDark),
                const SizedBox(height: AppDimensions.space20),
              ],

              // Content Area
              if (enquiryProvider.isLoading && enquiries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: LoadingIndicator(message: 'Loading enquiries...'),
                )
              else if (enquiries.isEmpty && !enquiryProvider.hasError)
                EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: 'No Enquiries Found',
                  description:
                      'No institutional enquiries match your active search and filter parameters.',
                  actionLabel: 'Reset Filters',
                  onActionPressed: () {
                    _searchController.clear();
                    enquiryProvider.clearFilters();
                  },
                )
              else ...[
                if (isDesktop)
                  _buildDesktopTable(
                    context,
                    enquiries: enquiries,
                    isDark: isDark,
                    canEdit: isRequester,
                  )
                else
                  _buildMobileCardList(
                    context,
                    enquiries: enquiries,
                    isDark: isDark,
                  ),

                const SizedBox(height: AppDimensions.space20),

                // Pagination Bar
                EnquiryPaginationBar(provider: enquiryProvider),
              ],

              const SizedBox(height: AppDimensions.space40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(
    BuildContext context,
    EnquiryProvider provider, {
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
                            'Search by subject, ID, sender or department...',
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
                    child: DropdownButtonFormField<EnquiryCategory?>(
                      initialValue: provider.categoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...EnquiryCategory.values.map(
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
                    child: DropdownButtonFormField<EnquiryPriority?>(
                      initialValue: provider.priorityFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Priorities'),
                        ),
                        ...EnquiryPriority.values.map(
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
                      hintText: 'Search enquiries...',
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
                        child: DropdownButtonFormField<EnquiryCategory?>(
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
                            ...EnquiryCategory.values.map(
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
                        child: DropdownButtonFormField<EnquiryPriority?>(
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
                            ...EnquiryPriority.values.map(
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

  Widget _buildStatusChips(
    BuildContext context,
    EnquiryProvider provider, {
    required bool isDark,
  }) {
    final statuses = [
      null,
      EnquiryStatus.open,
      EnquiryStatus.inProgress,
      EnquiryStatus.resolved,
      EnquiryStatus.closed,
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

  Widget _buildErrorCard(
    BuildContext context,
    EnquiryProvider provider, {
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.statusRejectedBg,
        borderRadius: AppDimensions.roundedMedium,
        border: Border.all(
          color: AppColors.statusRejected.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.statusRejected,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to load enquiries',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.statusRejected,
                  ),
                ),
                Text(
                  provider.errorMessage ??
                      'A network or server error occurred.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => provider.retry(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context, {
    required List<Enquiry> enquiries,
    required bool isDark,
    required bool canEdit,
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
                  child: Text('ENQUIRY ID', style: _headerStyle),
                ),
                Expanded(
                  flex: 4,
                  child: Text('SUBJECT & CATEGORY', style: _headerStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Text('SENDER & DEPT', style: _headerStyle),
                ),
                Expanded(flex: 2, child: Text('PRIORITY', style: _headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                Expanded(
                  flex: 2,
                  child: Text('LAST UPDATED', style: _headerStyle),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    'ACTIONS',
                    style: _headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: enquiries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final enq = enquiries[index];

              return InkWell(
                onTap: () => context.go('/enquiries/${enq.id}'),
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
                          enq.id,
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
                              enq.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              enq.category.displayName,
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
                      // Sender & Dept
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enq.senderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              enq.department,
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
                            enq.priority.displayName,
                          ),
                        ),
                      ),
                      // Status
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusBadge(
                            label: enq.status.displayName,
                            foregroundColor: enq.status.color,
                            backgroundColor: enq.status.backgroundColor,
                          ),
                        ),
                      ),
                      // Updated
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormatter.formatRelative(enq.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                      // Action
                      SizedBox(
                        width: 88,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit Enquiry',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: () =>
                                    context.go('/enquiries/${enq.id}/edit'),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                              ),
                              tooltip: 'View Details',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              onPressed: () =>
                                  context.go('/enquiries/${enq.id}'),
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

  Widget _buildMobileCardList(
    BuildContext context, {
    required List<Enquiry> enquiries,
    required bool isDark,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: enquiries.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) {
        return EnquirySummaryCard(enquiry: enquiries[index], isDark: isDark);
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
