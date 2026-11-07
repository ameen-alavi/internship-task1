import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/workflow_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workflow_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  final String? initialCategory;

  const CreateRequestScreen({super.key, this.initialCategory});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late WorkflowCategory _selectedCategory;
  PriorityLevel _selectedPriority = PriorityLevel.medium;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Dynamic Category-specific Controllers
  final TextEditingController _field1Controller =
      TextEditingController(); // Leave Type / Cert Type / Resource Type
  final TextEditingController _field2Controller =
      TextEditingController(); // Start Date / Purpose / Budget Amount
  final TextEditingController _field3Controller =
      TextEditingController(); // End Date / Copies / Vendor Name
  final TextEditingController _field4Controller =
      TextEditingController(); // Substitute / Delivery / Deadline

  @override
  void initState() {
    super.initState();
    _selectedCategory = _parseCategory(widget.initialCategory);
    _populateDefaultsForCategory(_selectedCategory);
  }

  WorkflowCategory _parseCategory(String? name) {
    if (name == null) return WorkflowCategory.leave;
    return WorkflowCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => WorkflowCategory.leave,
    );
  }

  void _populateDefaultsForCategory(WorkflowCategory category) {
    switch (category) {
      case WorkflowCategory.leave:
        _field1Controller.text = 'On-Duty Leave';
        _field2Controller.text = DateFormat(
          'MMM d, yyyy',
        ).format(DateTime.now().add(const Duration(days: 3)));
        _field3Controller.text = DateFormat(
          'MMM d, yyyy',
        ).format(DateTime.now().add(const Duration(days: 6)));
        _field4Controller.text = 'Prof. S. Nambiar (CSE Dept)';
        break;
      case WorkflowCategory.certificate:
        _field1Controller.text = 'Bonafide & NOC Certificate';
        _field2Controller.text = 'Academic Internship & Visa Application';
        _field3Controller.text = '2 Original Copies';
        _field4Controller.text = 'Digital PDF & Physical Seal';
        break;
      case WorkflowCategory.requisition:
        _field1Controller.text = 'Lab Hardware & Sensor Modules';
        _field2Controller.text = '\₹1,850.00 (INR)';
        _field3Controller.text = 'DigiKey / Mouser Electronics';
        _field4Controller.text = 'Next Semester Lab Sessions';
        break;
      case WorkflowCategory.clearance:
        _field1Controller.text = 'IRB Biomedical Human Subject Protocol';
        _field2Controller.text = 'Low Risk Non-Invasive Sensor Trial';
        _field3Controller.text = '30 Volunteer Participants';
        _field4Controller.text = 'Institutional Ethics Committee Review';
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _field1Controller.dispose();
    _field2Controller.dispose();
    _field3Controller.dispose();
    _field4Controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildMetadata() {
    switch (_selectedCategory) {
      case WorkflowCategory.leave:
        return {
          'leaveType': _field1Controller.text.trim(),
          'startDate': _field2Controller.text.trim(),
          'endDate': _field3Controller.text.trim(),
          'substituteFaculty': _field4Controller.text.trim(),
        };
      case WorkflowCategory.certificate:
        return {
          'certificateType': _field1Controller.text.trim(),
          'purpose': _field2Controller.text.trim(),
          'copies': _field3Controller.text.trim(),
          'deliveryMode': _field4Controller.text.trim(),
        };
      case WorkflowCategory.requisition:
        return {
          'resourceType': _field1Controller.text.trim(),
          'estimatedAmount': _field2Controller.text.trim(),
          'vendor': _field3Controller.text.trim(),
          'deadline': _field4Controller.text.trim(),
        };
      case WorkflowCategory.clearance:
        return {
          'protocolType': _field1Controller.text.trim(),
          'riskLevel': _field2Controller.text.trim(),
          'participants': _field3Controller.text.trim(),
          'ethicsReviewBody': _field4Controller.text.trim(),
        };
    }
  }

  Future<void> _submitRequest({bool isDraft = false}) async {
    if (!isDraft && !_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active user persona first.'),
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? '${_selectedCategory.displayName} Draft'
        : _titleController.text.trim();
    final description = _descController.text.trim().isEmpty
        ? 'No extended description provided.'
        : _descController.text.trim();

    final provider = context.read<WorkflowProvider>();
    final created = await provider.createRequest(
      title: title,
      category: _selectedCategory,
      description: description,
      requester: user,
      priority: _selectedPriority,
      metadata: _buildMetadata(),
      isDraft: isDraft,
    );

    if (mounted && created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Saved draft #${created.id}'
                : 'Workflow Application #${created.id} submitted successfully!',
          ),
          backgroundColor: isDraft
              ? AppColors.statusPending
              : AppColors.statusApproved,
        ),
      );
      context.go('/workflows/${created.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final workflowProvider = context.watch<WorkflowProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.space16 : AppDimensions.space24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        Text(
                          'Submit Workflow Application',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Complete all required fields for multi-stage departmental clearance',
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
                ],
              ),
              const SizedBox(height: AppDimensions.space24),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Form Fields
                        Expanded(
                          flex: 3,
                          child: _buildFormCard(context, isDark: isDark),
                        ),
                        const SizedBox(width: AppDimensions.space24),
                        // Right Column: Live Summary & Guide
                        Expanded(
                          flex: 2,
                          child: _buildSummarySidebar(context, isDark: isDark),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormCard(context, isDark: isDark),
                        const SizedBox(height: AppDimensions.space20),
                        _buildSummarySidebar(context, isDark: isDark),
                      ],
                    ),

              const SizedBox(height: AppDimensions.space32),

              // Action Buttons
              _buildBottomActionButtons(
                context,
                isLoading: workflowProvider.isActionLoading,
              ),
              const SizedBox(height: AppDimensions.space40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isDark}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            const Text(
              'APPLICATION CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkflowCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(cat.displayName),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: isDark
                      ? const Color(0xFF131D31)
                      : const Color(0xFFF1F5F9),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                        _populateDefaultsForCategory(cat);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.space24),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space24),

            // Request Title & Priority
            AppTextField(
              label: 'Request Title *',
              hint: 'e.g. Leave for Conference / GPU Quota Allocation',
              controller: _titleController,
              validator: (v) => Validators.minLength(
                v,
                6,
                'Please provide a descriptive title (at least 6 characters)',
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Priority Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgency / Priority Level *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: PriorityLevel.values.map((p) {
                    final isSelected = _selectedPriority == p;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : null,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () =>
                              setState(() => _selectedPriority = p),
                          child: Text(
                            p.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? AppColors.primary : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space24),

            // Dynamic Category Specific Fields
            _buildCategorySpecificFields(),
            const SizedBox(height: AppDimensions.space24),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space24),

            // Detailed Description
            AppTextField(
              label: 'Institutional Justification & Detailed Purpose *',
              hint:
                  'Describe the complete background, justification, and expected timeline...',
              controller: _descController,
              maxLines: 4,
              validator: (v) => Validators.minLength(
                v,
                20,
                'Please provide sufficient justification (minimum 20 characters)',
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySpecificFields() {
    switch (_selectedCategory) {
      case WorkflowCategory.leave:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Leave Classification',
                    controller: _field1Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Substitute Faculty / Staff',
                    controller: _field4Controller,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Start Date',
                    controller: _field2Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'End Date',
                    controller: _field3Controller,
                  ),
                ),
              ],
            ),
          ],
        );
      case WorkflowCategory.certificate:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Certificate Title',
                    controller: _field1Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Number of Copies',
                    controller: _field3Controller,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Purpose / Embassy Target',
                    controller: _field2Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Issuance & Delivery Format',
                    controller: _field4Controller,
                  ),
                ),
              ],
            ),
          ],
        );
      case WorkflowCategory.requisition:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Resource / Item Classification',
                    controller: _field1Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Estimated Cost / Amount',
                    controller: _field2Controller,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Preferred Vendor / Source',
                    controller: _field3Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Required By Date',
                    controller: _field4Controller,
                  ),
                ),
              ],
            ),
          ],
        );
      case WorkflowCategory.clearance:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Protocol / Proposal Type',
                    controller: _field1Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Subject Risk Level',
                    controller: _field2Controller,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Target Cohort / Participants',
                    controller: _field3Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Supervising Review Board',
                    controller: _field4Controller,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildSummarySidebar(BuildContext context, {required bool isDark}) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUBMISSION PREVIEW & ROUTING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Applicant Info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    user != null
                        ? user.name.split(' ').map((e) => e[0]).take(2).join()
                        : 'AA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
                        user?.name ?? 'Applicant Name',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.department ?? 'Department',
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
            const SizedBox(height: AppDimensions.space16),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),

            // Anticipated Stages
            const Text(
              'Multi-Stage Approval Pipeline',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildStagePreviewTile(
              '1',
              'Stage 1: Department Head Endorsement',
              'HOD / Direct Supervisor',
            ),
            const SizedBox(height: 8),
            _buildStagePreviewTile(
              '2',
              'Stage 2: Institutional Verification',
              'Registrar / Academic Office',
            ),
            const SizedBox(height: 8),
            _buildStagePreviewTile(
              '3',
              'Stage 3: Executive Sanction',
              'Dean / Institutional Director',
            ),

            const SizedBox(height: AppDimensions.space20),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.space16),

            // Institutional SLA Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppDimensions.roundedSmall,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Turnaround time for this category is typically 2–3 business days.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePreviewTile(String num, String title, String role) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(
    BuildContext context, {
    required bool isLoading,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isLoading ? null : () => _submitRequest(isDraft: true),
          child: const Text('Save Draft'),
        ),
        const SizedBox(width: AppDimensions.space16),
        AppButton(
          label: 'Submit Application',
          icon: Icons.send_rounded,
          isLoading: isLoading,
          onPressed: () => _submitRequest(isDraft: false),
        ),
      ],
    );
  }
}
