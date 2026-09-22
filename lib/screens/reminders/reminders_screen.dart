import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';
import 'widgets/reminder_card.dart';

enum _ReminderFilter { all, upcoming, overdue }

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  _ReminderFilter _selectedFilter = _ReminderFilter.all;

  String _getStatus(ReminderModel reminder) {
    final today = DateUtils.dateOnly(DateTime.now());
    final reminderDate = DateUtils.dateOnly(reminder.date);

    if (reminderDate.isBefore(today)) {
      return 'Overdue';
    }

    return 'Upcoming';
  }

  String _getTiming(ReminderModel reminder) {
    final today = DateUtils.dateOnly(DateTime.now());
    final reminderDate = DateUtils.dateOnly(reminder.date);

    final difference = reminderDate.difference(today).inDays;

    if (difference < 0) {
      final days = difference.abs();

      return days == 1 ? '1 day ago' : '$days days ago';
    }

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'In 1 day';
    }

    return 'In $difference days';
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'HVAC':
        return Icons.ac_unit_rounded;

      case 'Refrigerator':
        return Icons.kitchen_rounded;

      case 'Water Filter':
        return Icons.water_drop_outlined;

      case 'Washing Machine':
        return Icons.local_laundry_service_outlined;

      case 'Electrical':
        return Icons.electrical_services_rounded;

      case 'Plumbing':
        return Icons.plumbing_rounded;

      default:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view reminders.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/reminders/create');
        },
        tooltip: 'Create reminder',
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.surface,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: context.read<ReminderProvider>().getReminders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load reminders.'));
          }

          final reminders = snapshot.data ?? [];

          final upcoming = reminders
              .where((reminder) => _getStatus(reminder) == 'Upcoming')
              .toList();

          final overdue = reminders
              .where((reminder) => _getStatus(reminder) == 'Overdue')
              .toList();

          final visibleReminders = switch (_selectedFilter) {
            _ReminderFilter.all => reminders,
            _ReminderFilter.upcoming => upcoming,
            _ReminderFilter.overdue => overdue,
          };

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingMedium,
                AppConstants.paddingSmall,
                AppConstants.paddingMedium,
                96,
              ),
              children: [
                Row(
                  children: [
                    const AppLogo(height: 48, width: 48),
                    const SizedBox(width: 10),
                    Text(
                      'HomiQ',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // Notifications will be connected later.
                      },
                      tooltip: 'Notifications',
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Reminders', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Keep your home in great shape.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${reminders.length})',
                        isSelected: _selectedFilter == _ReminderFilter.all,
                        onSelected: () {
                          setState(() {
                            _selectedFilter = _ReminderFilter.all;
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      _FilterChip(
                        label: 'Upcoming (${upcoming.length})',
                        isSelected: _selectedFilter == _ReminderFilter.upcoming,
                        onSelected: () {
                          setState(() {
                            _selectedFilter = _ReminderFilter.upcoming;
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      _FilterChip(
                        label: 'Overdue (${overdue.length})',
                        isSelected: _selectedFilter == _ReminderFilter.overdue,
                        onSelected: () {
                          setState(() {
                            _selectedFilter = _ReminderFilter.overdue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                if (visibleReminders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No reminders found.',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < visibleReminders.length;
                    index++
                  ) ...[
                    ReminderCard(
                      title: visibleReminders[index].title,
                      location: visibleReminders[index].location,
                      dueDate: _formatDate(
                        context,
                        visibleReminders[index].date,
                      ),
                      status: _getStatus(visibleReminders[index]),
                      timing: _getTiming(visibleReminders[index]),
                      applianceIcon: _getIcon(visibleReminders[index].category),
                    ),
                    if (index != visibleReminders.length - 1)
                      const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected ? AppColors.primaryBlue : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
