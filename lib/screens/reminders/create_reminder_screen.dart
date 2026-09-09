import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  static const _categories = [
    'HVAC',
    'Refrigerator',
    'Water Filter',
    'Washing Machine',
    'Electrical',
    'Plumbing',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year + 100, 12, 31),
    );
    if (!mounted || date == null) return;
    _selectedDate = date;
    _dateController.text = MaterialLocalizations.of(
      context,
    ).formatMediumDate(date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (!mounted || time == null) return;
    _selectedTime = time;
    _timeController.text = time.format(context);
  }

  void _validateReminder() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // TODO: Connect validated form values to reminder persistence later.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Reminder details are valid. Saving is not available yet.',
          ),
        ),
      );
  }

  Widget _field({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Semantics(label: label, child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Create Reminder'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reminders');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  label: 'Title *',
                  child: TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'E.g. AC Service',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a title.'
                        : null,
                  ),
                ),
                _field(
                  label: 'Category *',
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select a category',
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (_) {},
                    validator: (value) =>
                        value == null ? 'Please select a category.' : null,
                  ),
                ),
                _field(
                  label: 'Appliance / Location',
                  child: TextFormField(
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'E.g. Living Room AC',
                    ),
                  ),
                ),
                _field(
                  label: 'Date *',
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      hintText: 'Select date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) =>
                        _selectedDate == null ? 'Please select a date.' : null,
                  ),
                ),
                _field(
                  label: 'Time',
                  child: TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      hintText: 'Select time (optional)',
                      suffixIcon: Icon(Icons.access_time_rounded),
                    ),
                  ),
                ),
                _field(
                  label: 'Notes',
                  child: TextFormField(
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 200,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add any notes (optional)',
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                PrimaryButton(
                  text: 'Save Reminder',
                  onPressed: _validateReminder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
