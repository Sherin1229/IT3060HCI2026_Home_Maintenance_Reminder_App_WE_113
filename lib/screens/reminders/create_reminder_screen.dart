import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/appliance_selection_field.dart';
import 'reminder_schedule_screen.dart';
import 'widgets/reminder_schedule_card.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedApplianceId;
  ReminderScheduleSelection? _schedule;
  bool _hasAttemptedSubmit = false;
  bool _showScheduleError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openSchedule() async {
    final schedule = await context.push<ReminderScheduleSelection>(
      '/reminders/schedule',
      extra: _schedule,
    );
    if (schedule != null && mounted) {
      setState(() {
        _schedule = schedule;
        _showScheduleError = false;
      });
    }
  }

  String _scheduleSummary(BuildContext context) {
    final schedule = _schedule;
    if (schedule == null) return 'Set frequency, date and time';
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(schedule.date);
    return '${schedule.frequency} • $date • ${schedule.time.format(context)}';
  }

  Future<void> _saveReminder() async {
    FocusScope.of(context).unfocus();

    final schedule = _schedule;
    setState(() {
      _hasAttemptedSubmit = true;
      _showScheduleError = schedule == null;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (schedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a reminder schedule.')),
      );
    }

    if (!isFormValid || schedule == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a reminder.'),
        ),
      );
      return;
    }

    final reminder = ReminderModel(
      id: '',
      userId: user.uid,
      applianceId: _selectedApplianceId,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      location: _locationController.text.trim(),
      date: schedule.date,
      time: schedule.time.format(context),
      frequency: schedule.frequency,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final reminderProvider = context.read<ReminderProvider>();

    final success = await reminderProvider.createReminder(reminder);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder created successfully.')),
      );

      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reminderProvider.errorMessage ??
                'Unable to save reminder. Please try again.',
          ),
        ),
      );
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.paddingMedium,
                  ),
                  child: ApplianceSelectionField(
                    label: 'Appliance (Optional)',
                    selectedApplianceId: _selectedApplianceId,
                    onChanged: (appliance) =>
                        setState(() => _selectedApplianceId = appliance?.id),
                  ),
                ),
                _field(
                  label: 'Title *',
                  child: TextFormField(
                    controller: _titleController,
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
                  child: TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'E.g. Cleaning, Safety, Payment',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a category.'
                        : null,
                  ),
                ),
                _field(
                  label: 'Location',
                  child: TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'E.g. Living Room',
                    ),
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
                  text: 'Save Reminder',
                  onPressed: _saveReminder,
                  isLoading: context.watch<ReminderProvider>().isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
