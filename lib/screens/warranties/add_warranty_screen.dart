import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

class AddWarrantyScreen extends StatefulWidget {
  const AddWarrantyScreen({super.key});

  @override
  State<AddWarrantyScreen> createState() => _AddWarrantyScreenState();
}

class _AddWarrantyScreenState extends State<AddWarrantyScreen> {
  static const _applianceOptions = [
    'Refrigerator',
    'Washing Machine',
    'Air Conditioner',
    'TV',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _providerController = TextEditingController();
  final _notesController = TextEditingController();

  String? _applianceType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/warranties');
    }
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select warranty start date',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _startDate = DateUtils.dateOnly(selectedDate);
      _startDateController.text = _formatDate(selectedDate);
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select warranty end date',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _endDate = DateUtils.dateOnly(selectedDate);
      _endDateController.text = _formatDate(selectedDate);
    });
  }

  String? _requiredTextValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }
    return null;
  }

  void _continueToNextStep() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Appliance details are ready. Document Upload is the next step.',
          ),
        ),
      );
    // TODO: Navigate to Document Upload when Step 2 is implemented.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          tooltip: 'Back to warranties',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Add Warranty'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
              AppConstants.paddingLarge,
            ),
            children: [
              const _WarrantyStepIndicator(),
              const SizedBox(height: 28),
              _FormRow(
                icon: Icons.kitchen_outlined,
                label: 'Appliance Type',
                isRequired: true,
                child: DropdownButtonFormField<String>(
                  initialValue: _applianceType,
                  isExpanded: true,
                  hint: const Text('Select appliance'),
                  items: _applianceOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _applianceType = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select an appliance type.' : null,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.sell_outlined,
                label: 'Brand',
                isRequired: true,
                child: TextFormField(
                  controller: _brandController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Enter brand'),
                  validator: (value) => _requiredTextValidator(value, 'brand'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.view_in_ar_outlined,
                label: 'Model',
                isRequired: true,
                child: TextFormField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter model number',
                  ),
                  validator: (value) => _requiredTextValidator(value, 'model'),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.calendar_month_outlined,
                label: 'Warranty Start Date',
                isRequired: true,
                child: TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  onTap: _selectStartDate,
                  decoration: const InputDecoration(
                    hintText: 'Select date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (_) => _startDate == null
                      ? 'Please select a warranty start date.'
                      : null,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.event_available_outlined,
                label: 'Warranty End Date',
                isRequired: true,
                child: TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  onTap: _selectEndDate,
                  decoration: const InputDecoration(
                    hintText: 'Select date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (_) {
                    if (_endDate == null) {
                      return 'Please select a warranty end date.';
                    }
                    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                      return 'End date cannot be earlier than start date.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.business_outlined,
                label: 'Provider / Company',
                child: TextFormField(
                  controller: _providerController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Enter provider / company',
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _FormRow(
                icon: Icons.notes_rounded,
                label: 'Notes (Optional)',
                alignIconToTop: true,
                child: TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Add any additional notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _continueToNextStep,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next'),
                    SizedBox(width: AppConstants.paddingSmall),
                    Icon(Icons.arrow_forward_rounded, size: 21),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantyStepIndicator extends StatelessWidget {
  const _WarrantyStepIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Step 1 of 2, Appliance Details',
      child: Column(
        children: [
          Row(
            children: [
              const _StepCircle(number: '1', isActive: true),
              Expanded(child: Container(height: 2, color: AppColors.border)),
              const _StepCircle(number: '2', isActive: false),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Appliance Details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Document Upload',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String number;
  final bool isActive;

  const _StepCircle({required this.number, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primaryBlue : AppColors.border,
          width: 2,
        ),
      ),
      child: Text(
        number,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isActive ? AppColors.surface : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRequired;
  final bool alignIconToTop;
  final Widget child;

  const _FormRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.alignIconToTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: alignIconToTop ? 28 : 26),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  children: isRequired
                      ? const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ]
                      : const [],
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
