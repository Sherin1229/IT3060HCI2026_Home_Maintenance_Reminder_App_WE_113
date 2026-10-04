import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import 'reminder_schedule_screen.dart';
import 'widgets/reminder_schedule_card.dart';

class EditReminderScreen extends StatefulWidget {
  final String reminderId;

  const EditReminderScreen({super.key, required this.reminderId});

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
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderModel? _loadedReminder;
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _frequency = 'Does not repeat';
  ReminderScheduleSelection? _schedule;
  bool _isSaving = false;
  bool _showScheduleError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!) ?? -1;
    final minute = int.tryParse(match.group(2)!) ?? -1;
    final period = match.group(3)?.toUpperCase();
    if (minute < 0 || minute > 59) return null;
    if (period != null) {
      if (hour < 1 || hour > 12) return null;
      if (period == 'AM' && hour == 12) hour = 0;
      if (period == 'PM' && hour != 12) hour += 12;
    }
    if (hour < 0 || hour > 23) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _initializeForm(ReminderModel reminder) {
    if (_loadedReminder != null) return;
    _loadedReminder = reminder;
    _titleController.text = reminder.title;
    _locationController.text = reminder.location;
    _notesController.text = reminder.notes ?? '';
    _selectedCategory = _categories.contains(reminder.category)
        ? reminder.category
        : 'Other';
    _selectedDate = reminder.date;
    _selectedTime = _parseTime(reminder.time);
    _frequency = reminder.frequency;
    if (_selectedTime != null) {
      _schedule = ReminderScheduleSelection(
        frequency: _frequency,
        date: reminder.date,
        time: _selectedTime!,
      );
    }
  }

  Future<void> _openSchedule() async {
    final initialSelection =
        _schedule ??
        ReminderScheduleSelection(
          frequency: _frequency,
          date: _selectedDate ?? DateUtils.dateOnly(DateTime.now()),
          time: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
        );
    final schedule = await context.push<ReminderScheduleSelection>(
      '/reminders/schedule',
      extra: initialSelection,
    );
    if (schedule == null || !mounted) return;
    setState(() {
      _schedule = schedule;
      _frequency = schedule.frequency;
      _selectedDate = schedule.date;
      _selectedTime = schedule.time;
      _showScheduleError = false;
    });
  }

  String _scheduleSummary(BuildContext context) {
    final date = _selectedDate;
    if (date == null) return 'Set frequency and date';
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(date);
    final time = _selectedTime?.format(context) ?? 'Not set';
    return '$_frequency • $formattedDate • $time';
  }

  Future<void> _updateReminder() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final schedule = _schedule;
    if (schedule == null) {
      setState(() => _showScheduleError = true);
      _showMessage('Please set a reminder schedule.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final original = _loadedReminder;
    if (user == null || original == null) {
      _showMessage('Reminder information is unavailable.');
      return;
    }
    setState(() => _isSaving = true);
    final updatedReminder = ReminderModel(
      id: widget.reminderId,
      userId: user.uid,
      title: _titleController.text.trim(),
      category: _selectedCategory!,
      location: _locationController.text.trim(),
      date: schedule.date,
      time: schedule.time.format(context),
      frequency: schedule.frequency,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isCompleted: original.isCompleted,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
    );
    final provider = context.read<ReminderProvider>();
    final success = await provider.updateReminder(updatedReminder);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      _showMessage('Reminder updated successfully.');
      context.pop();
    } else {
      _showMessage(provider.errorMessage ?? 'Unable to update reminder.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
              color: Theme.of(context).colorScheme.onSurface,
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
    final user = FirebaseAuth.instance.currentUser;
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
      body: user == null
          ? const Center(child: Text('Please log in to edit this reminder.'))
          : StreamBuilder<ReminderModel?>(
              stream: context.read<ReminderProvider>().getReminderById(
                widget.reminderId,
                user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _loadedReminder == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load reminder.'));
                }
                final reminder = snapshot.data ?? _loadedReminder;
                if (reminder == null) {
                  return const Center(
                    child: Text('Reminder information is unavailable.'),
                  );
                }
                _initializeForm(reminder);
                return _buildForm();
              },
            ),
    );
  }

  Widget _buildForm() {
    return SafeArea(
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
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
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
              ReminderScheduleCard(
                summary: _scheduleSummary(context),
                isConfigured: _schedule != null,
                onTap: _openSchedule,
              ),
              if (_showScheduleError) ...[
                const SizedBox(height: 6),
                Text(
                  'Please set a reminder schedule.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
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
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
