import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import 'reminder_schedule_screen.dart';
import 'widgets/reminder_schedule_card.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({super.key});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
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
  final _titleController = TextEditingController(text: 'AC Service');
  final _locationController = TextEditingController(text: 'Living Room');
  final _dateController = TextEditingController(text: '15 May 2025');
  final _timeController = TextEditingController(text: '10:00 AM');
  final _notesController = TextEditingController(
    text: 'Check filter, clean coils, and inspect gas levels.',
  );

  String? _selectedCategory = 'HVAC';
  DateTime? _selectedDate = DateTime(2025, 5, 15);
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  ReminderScheduleSelection _schedule = ReminderScheduleSelection(
    frequency: 'Every 6 months',
    date: DateTime(2025, 5, 15),
    time: const TimeOfDay(hour: 10, minute: 0),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      _selectedDate = date;
      _dateController.text = MaterialLocalizations.of(
        context,
      ).formatMediumDate(date);
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _selectedTime = time;
      _timeController.text = time.format(context);
    });
  }

  Future<void> _openSchedule() async {
    final schedule = await context.push<ReminderScheduleSelection>(
      '/reminders/schedule',
      extra: _schedule,
    );
    if (schedule != null && mounted) setState(() => _schedule = schedule);
  }

  String _scheduleSummary(BuildContext context) {
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_schedule.date);
    return '${_schedule.frequency} • $date • ${_schedule.time.format(context)}';
  }

  void _updateReminder() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // TODO: Persist reminder updates during backend integration.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Reminder changes saved locally for preview.'),
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
    // TODO: Load selected reminder data during backend integration.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to reminder details',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Edit Reminder'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
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
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a title.'
                        : null,
                  ),
                ),
                _field(
                  label: 'Category *',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select a category.' : null,
                  ),
                ),
                _field(
                  label: 'Appliance / Location',
                  child: TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                _field(
                  label: 'Date *',
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
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
                      suffixIcon: Icon(Icons.access_time_rounded),
                    ),
                  ),
                ),
                ReminderScheduleCard(
                  summary: _scheduleSummary(context),
                  isConfigured: true,
                  onTap: _openSchedule,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                _field(
                  label: 'Notes',
                  child: TextFormField(
                    controller: _notesController,
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
                  text: 'Update Reminder',
                  onPressed: _updateReminder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
