import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../data/models/enquiry_model.dart';
import '../../../providers/enquiry_provider.dart';

class EditEnquiryScreen extends StatefulWidget {
  final String enquiryId;

  const EditEnquiryScreen({super.key, required this.enquiryId});

  @override
  State<EditEnquiryScreen> createState() => _EditEnquiryScreenState();
}

class _EditEnquiryScreenState extends State<EditEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  EnquiryCategory? _selectedCategory;
  EnquiryPriority? _selectedPriority;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _assignedController = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EnquiryProvider>();
      final enq = await provider.fetchEnquiryById(widget.enquiryId);
      if (mounted && enq != null) {
        setState(() {
          _titleController.text = enq.title;
          _descController.text = enq.description;
          _deptController.text = enq.department;
          _phoneController.text = enq.senderPhone ?? '';
          _assignedController.text = enq.assignedTo ?? '';
          _selectedCategory = enq.category;
          _selectedPriority = enq.priority;
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deptController.dispose();
    _phoneController.dispose();
    _assignedController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<EnquiryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final dto = UpdateEnquiryDto(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
      department: _deptController.text.trim(),
      senderPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      priority: _selectedPriority,
      assignedTo: _assignedController.text.trim().isEmpty
          ? null
          : _assignedController.text.trim(),
    );

    final updated = await provider.updateEnquiry(widget.enquiryId, dto);

    if (mounted) {
      if (updated != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Enquiry #${updated.id} updated successfully!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        context.go('/enquiries/${updated.id}');
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update enquiry.'),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final provider = context.watch<EnquiryProvider>();

    if (provider.isLoading && !_isInitialized) {
      return const LoadingIndicator(message: 'Loading enquiry for editing...');
    }

    if (provider.selectedEnquiry == null && !_isInitialized) {
      return Scaffold(
        body: EmptyStateWidget(
          icon: Icons.find_in_page_outlined,
          title: 'Enquiry Not Found',
          description: 'Cannot edit enquiry #${widget.enquiryId}.',
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
                    onPressed: () =>
                        context.go('/enquiries/${widget.enquiryId}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Enquiry #${widget.enquiryId}',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Modify enquiry details, category classification, or assigned department',
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

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(
                        isMobile
                            ? AppDimensions.space20
                            : AppDimensions.space32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector
                          const Text(
                            'ENQUIRY CATEGORY *',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: EnquiryCategory.values.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                selected: isSelected,
                                label: Text(cat.displayName),
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
                                    setState(() => _selectedCategory = cat);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppDimensions.space24),
                          const Divider(height: 1),
                          const SizedBox(height: AppDimensions.space24),

                          // Subject & Priority
                          AppTextField(
                            label: 'Subject / Title *',
                            controller: _titleController,
                            validator: (v) => Validators.minLength(
                              v,
                              6,
                              'Subject must be at least 6 characters',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          // Priority Selector
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Priority Level *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              Row(
                                children: EnquiryPriority.values.map((p) {
                                  final isSelected = _selectedPriority == p;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: isSelected
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.12,
                                                )
                                              : null,
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                      ? AppColors.borderDark
                                                      : AppColors.borderLight),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () => setState(
                                          () => _selectedPriority = p,
                                        ),
                                        child: Text(
                                          p.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.primary
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          // Target Department & Assigned Staff
                          isDesktop
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Department *',
                                        controller: _deptController,
                                        validator: (v) =>
                                            Validators.requiredField(
                                              v,
                                              'Department is required',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppTextField(
                                        label:
                                            'Assigned Staff / Officer (Optional)',
                                        hint: 'e.g. Dr. K. R. Sharma',
                                        controller: _assignedController,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    AppTextField(
                                      label: 'Department *',
                                      controller: _deptController,
                                      validator: (v) =>
                                          Validators.requiredField(
                                            v,
                                            'Department is required',
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label:
                                          'Assigned Staff / Officer (Optional)',
                                      hint: 'e.g. Dr. K. R. Sharma',
                                      controller: _assignedController,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: AppDimensions.space20),

                          // Contact Phone
                          AppTextField(
                            label: 'Sender Contact Phone',
                            hint: '+91 98450 00000',
                            controller: _phoneController,
                          ),
                          const SizedBox(height: AppDimensions.space24),
                          const Divider(height: 1),
                          const SizedBox(height: AppDimensions.space24),

                          // Description
                          AppTextField(
                            label: 'Enquiry Description & Requirements *',
                            controller: _descController,
                            maxLines: 5,
                            validator: (v) => Validators.minLength(
                              v,
                              15,
                              'Please provide sufficient description (minimum 15 characters)',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Submit Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: provider.isActionLoading
                                    ? null
                                    : () => context.go(
                                        '/enquiries/${widget.enquiryId}',
                                      ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              AppButton(
                                label: 'Save Changes',
                                icon: Icons.save_rounded,
                                isLoading: provider.isActionLoading,
                                onPressed: _submitUpdate,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space40),
            ],
          ),
        ),
      ),
    );
  }
}
