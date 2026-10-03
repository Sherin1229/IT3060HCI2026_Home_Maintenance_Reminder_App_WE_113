import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

class ReminderScheduleSelection {
  final String frequency;
  final DateTime date;
  final TimeOfDay time;

  const ReminderScheduleSelection({
    required this.frequency,
    required this.date,
    required this.time,
  });
}

class ReminderScheduleScreen extends StatefulWidget {
  final ReminderScheduleSelection? initialSelection;

  const ReminderScheduleScreen({super.key, this.initialSelection});

  @override
  State<ReminderScheduleScreen> createState() => _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState extends State<ReminderScheduleScreen> {
  static const _frequencies = [
    'Does not repeat',
    'Weekly',
    'Monthly',
    'Every 3 months',
    'Every 6 months',
    'Yearly',
  ];

  late String _frequency;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _frequency = widget.initialSelection?.frequency ?? 'Monthly';
    _selectedDate = widget.initialSelection?.date ?? today;
    _selectedTime =
        widget.initialSelection?.time ?? const TimeOfDay(hour: 10, minute: 0);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) setState(() => _selectedTime = time);
  }

  void _confirmSchedule() {
    context.pop(
      ReminderScheduleSelection(
        frequency: _frequency,
        date: _selectedDate,
        time: _selectedTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to create reminder',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Set Schedule'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                children: [
                  _Label(
                    text: 'Frequency',
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      isExpanded: true,
                      items: _frequencies
                          .map(
                            (frequency) => DropdownMenuItem(
                              value: frequency,
                              child: Text(frequency),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _frequency = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Card(
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(today.year + 10, 12, 31),
                      onDateChanged: (date) {
                        setState(() => _selectedDate = date);
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    'Time',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ElevatedButton(
                onPressed: _confirmSchedule,
                child: const Text('Confirm Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Widget child;

  const _Label({required this.text, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        child,
      ],
    );
  }
}
