import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/enquiry_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/enquiry_provider.dart';

class CreateEnquiryScreen extends StatefulWidget {
  const CreateEnquiryScreen({super.key});

  @override
  State<CreateEnquiryScreen> createState() => _CreateEnquiryScreenState();
}

class _CreateEnquiryScreenState extends State<CreateEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  EnquiryCategory _selectedCategory = EnquiryCategory.admissions;
  EnquiryPriority _selectedPriority = EnquiryPriority.medium;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _deptController = TextEditingController(
    text: 'Admissions & Academic Affairs',
  );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      _nameController.text = auth.currentUser!.name;
      _emailController.text = auth.currentUser!.email;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _deptController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<EnquiryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final dto = CreateEnquiryDto(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
      senderName: context.read<AuthProvider>().currentUser!.name,
      senderEmail: context.read<AuthProvider>().currentUser!.email,
      senderUserId: context.read<AuthProvider>().currentUser!.id,
      senderPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      department: _deptController.text.trim(),
      priority: _selectedPriority,
    );

    final created = await provider.createEnquiry(dto);

    if (mounted) {
      if (created != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Enquiry #${created.id} submitted successfully!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        context.go('/enquiries/${created.id}');
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to submit enquiry.'),
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
                    onPressed: () => context.go('/enquiries'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit New Enquiry',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Submit an institutional enquiry or ticket to the responsible department',
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
                                    setState(() {
                                      _selectedCategory = cat;
                                      _deptController.text =
                                          _getDefaultDepartment(cat);
                                    });
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
                            hint:
                                'e.g. M.Tech Data Science Credit Transfer Query',
                            controller: _titleController,
                            validator: (v) => Validators.minLength(
                              v,
                              6,
                              'Please provide a clear subject (at least 6 characters)',
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

                          // Target Department
                          AppTextField(
                            label: 'Assigned / Target Department *',
                            hint: 'Department handling this query',
                            controller: _deptController,
                            validator: (v) => Validators.requiredField(
                              v,
                              'Target department required',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space24),
                          const Divider(height: 1),
                          const SizedBox(height: AppDimensions.space24),

                          // Sender Details Row
                          isDesktop
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Full Name *',
                                        hint: 'Your name',
                                        controller: _nameController,
                                        validator: (v) =>
                                            Validators.requiredField(
                                              v,
                                              'Name is required',
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Email Address *',
                                        hint: 'name@edusphere.com',
                                        controller: _emailController,
                                        validator: Validators.email,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppTextField(
                                        label: 'Phone Number (Optional)',
                                        hint: '+91 98450 00000',
                                        controller: _phoneController,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    AppTextField(
                                      label: 'Full Name *',
                                      hint: 'Your name',
                                      controller: _nameController,
                                      validator: (v) =>
                                          Validators.requiredField(
                                            v,
                                            'Name is required',
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label: 'Email Address *',
                                      hint: 'name@edusphere.com',
                                      controller: _emailController,
                                      validator: Validators.email,
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      label: 'Phone Number (Optional)',
                                      hint: '+91 98450 00000',
                                      controller: _phoneController,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: AppDimensions.space24),
                          const Divider(height: 1),
                          const SizedBox(height: AppDimensions.space24),

                          // Detailed Description
                          AppTextField(
                            label: 'Enquiry Description & Specific Questions *',
                            hint:
                                'Provide full details, background, and specific information requested...',
                            controller: _descController,
                            maxLines: 5,
                            validator: (v) => Validators.minLength(
                              v,
                              15,
                              'Please provide sufficient description (minimum 15 characters)',
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Submit Action Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: provider.isActionLoading
                                    ? null
                                    : () => context.go('/enquiries'),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              AppButton(
                                label: 'Submit Enquiry',
                                icon: Icons.send_rounded,
                                isLoading: provider.isActionLoading,
                                onPressed: _submitForm,
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

  String _getDefaultDepartment(EnquiryCategory cat) {
    switch (cat) {
      case EnquiryCategory.admissions:
        return 'Admissions & Academic Affairs';
      case EnquiryCategory.academic:
        return 'Academic Advising & Registrar';
      case EnquiryCategory.financial:
        return 'Finance & Student Accounts';
      case EnquiryCategory.hostel:
        return 'Campus & Hostel Facilities';
      case EnquiryCategory.general:
        return 'Office of Student Affairs';
    }
  }
}
