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
import '../../../providers/auth_provider.dart';
import '../../../providers/enquiry_provider.dart';

class EnquiryDetailsScreen extends StatefulWidget {
  final String enquiryId;

  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  @override
  State<EnquiryDetailsScreen> createState() => _EnquiryDetailsScreenState();
}

class _EnquiryDetailsScreenState extends State<EnquiryDetailsScreen> {
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnquiryProvider>().fetchEnquiryById(
        widget.enquiryId,
        viewerEmail: context.read<AuthProvider>().currentUser?.email,
        viewerRole: context.read<AuthProvider>().currentUser?.role,
      );
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse(Enquiry enq) async {
    final text = _responseController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null || user.role != UserRole.approver) return;

    final provider = context.read<EnquiryProvider>();
    final ok = await provider.addResponse(enq.id, message: text, author: user);
    if (ok) {
      _responseController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final enquiryProvider = context.watch<EnquiryProvider>();
    final enq = enquiryProvider.selectedEnquiry;

    if (enquiryProvider.isLoading && enq == null) {
      return const LoadingIndicator(message: 'Loading enquiry details...');
    }

    if (enq == null) {
      return Scaffold(
        body: EmptyStateWidget(
          icon: Icons.find_in_page_outlined,
          title: 'Enquiry Not Found',
          description:
              'The enquiry with ID "${widget.enquiryId}" could not be located.',
          actionLabel: 'Return to Enquiries',
          onActionPressed: () => context.go('/enquiries'),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Action Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/enquiries'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            enq.id,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          if (context.read<AuthProvider>().isApprover)
                            _buildStatusDropdown(context, enq),
                          if (!context.read<AuthProvider>().isApprover)
                            StatusBadge(
                              label: enq.status.displayName,
                              foregroundColor: enq.status.color,
                              backgroundColor: enq.status.backgroundColor,
                            ),
                          StatusBadge.forPriority(enq.priority.displayName),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enq.title,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (context.read<AuthProvider>().isRequester)
                  AppButton(
                    label: isMobile ? 'Edit' : 'Edit Enquiry',
                    icon: Icons.edit_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.go('/enquiries/${enq.id}/edit'),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Main Content Area
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column (60%): Overview, Description, Sender Details
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSenderCard(context, enq: enq, isDark: isDark),
                            const SizedBox(height: AppDimensions.space20),
                            _buildDescriptionCard(
                              context,
                              enq: enq,
                              isDark: isDark,
                            ),
                            if (enq.attachments.isNotEmpty) ...[
                              const SizedBox(height: AppDimensions.space20),
                              _buildAttachmentsCard(
                                context,
                                enq: enq,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space24),
                      // Right Column (40%): Status Actions & Response History
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildResponsesCard(
                              context,
                              enq: enq,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSenderCard(context, enq: enq, isDark: isDark),
                      const SizedBox(height: AppDimensions.space16),
                      _buildDescriptionCard(context, enq: enq, isDark: isDark),
                      if (enq.attachments.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space16),
                        _buildAttachmentsCard(
                          context,
                          enq: enq,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space16),
                      _buildResponsesCard(context, enq: enq, isDark: isDark),
                    ],
                  ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, Enquiry enq) {
    const approverStatuses = [
      EnquiryStatus.open,
      EnquiryStatus.inProgress,
      EnquiryStatus.closed,
    ];
    return Container(
      padding: const EdgeInsets.only(left: 9, right: 3),
      decoration: BoxDecoration(
        color: enq.status.backgroundColor,
        borderRadius: AppDimensions.roundedSmall,
      ),
      child: DropdownButton<EnquiryStatus>(
        value: approverStatuses.contains(enq.status)
            ? enq.status
            : EnquiryStatus.closed,
        underline: const SizedBox.shrink(),
        isDense: true,
        iconSize: 16,
        style: TextStyle(color: enq.status.color, fontSize: 12),
        items: approverStatuses
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status.displayName),
              ),
            )
            .toList(),
        onChanged: context.read<EnquiryProvider>().isActionLoading
            ? null
            : (status) async {
                if (status == null || status == enq.status) return;
                final approver = context.read<AuthProvider>().currentUser;
                if (approver == null || approver.role != UserRole.approver)
                  return;
                final ok = await context.read<EnquiryProvider>().updateStatus(
                  enq.id,
                  status,
                  notes: 'Status updated by approver.',
                  staff: approver,
                );
                if (mounted && !ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to update enquiry status.'),
                    ),
                  );
                }
              },
      ),
    );
  }

  Widget _buildSenderCard(
    BuildContext context, {
    required Enquiry enq,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SENDER & ROUTING INFORMATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    enq.senderName.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enq.senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${enq.senderEmail}${enq.senderPhone != null ? ' • ${enq.senderPhone}' : ''}',
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
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildInfoField('CATEGORY', enq.category.displayName, isDark),
                _buildInfoField('DEPARTMENT', enq.department, isDark),
                _buildInfoField(
                  'ASSIGNED TO',
                  enq.assignedTo ?? 'Unassigned',
                  isDark,
                ),
                _buildInfoField(
                  'SUBMITTED',
                  DateFormatter.formatDateTime(enq.createdAt),
                  isDark,
                ),
                if (enq.resolvedAt != null)
                  _buildInfoField(
                    'RESOLVED AT',
                    DateFormatter.formatDateTime(enq.resolvedAt!),
                    isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(
    BuildContext context, {
    required Enquiry enq,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENQUIRY DESCRIPTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
            Text(
              enq.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (enq.metadata.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Context Metadata:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: enq.metadata.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF1F5F9),
                      borderRadius: AppDimensions.roundedSmall,
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesCard(
    BuildContext context, {
    required Enquiry enq,
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
                  'RESPONSE & REMARKS THREAD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${enq.responses.length} messages',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            if (enq.responses.isEmpty)
              const Text(
                'No responses or official remarks yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enq.responses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final resp = enq.responses[index];

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
                          children: [
                            Expanded(
                              child: Text(
                                '${resp.authorName} (${resp.authorRole})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatRelative(resp.createdAt),
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
                        Text(
                          resp.message,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: AppDimensions.space16),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),

            if (context.read<AuthProvider>().isApprover) ...[
              // Reply Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _responseController,
                      decoration: const InputDecoration(
                        hintText: 'Type an official reply or note...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _submitResponse(enq),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: () => _submitResponse(enq),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(
    BuildContext context, {
    required Enquiry enq,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUPPORTING DOCUMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enq.attachments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final att = enq.attachments[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131D31)
                        : const Color(0xFFF1F5F9),
                    borderRadius: AppDimensions.roundedMedium,
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.statusRejected,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              att.formattedSize,
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

  Widget _buildInfoField(String label, String value, bool isDark) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
