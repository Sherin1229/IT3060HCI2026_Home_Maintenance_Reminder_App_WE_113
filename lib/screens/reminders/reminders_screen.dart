import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_logo.dart';
import 'widgets/reminder_card.dart';

enum _ReminderFilter { all, upcoming, overdue }

class _ReminderItem {
  final String title;
  final String location;
  final String date;
  final String status;
  final String timing;
  final IconData icon;

  const _ReminderItem({
    required this.title,
    required this.location,
    required this.date,
    required this.status,
    required this.timing,
    required this.icon,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const _reminders = [
    _ReminderItem(
      title: 'AC Service',
      location: 'Living Room',
      date: '15 May 2025',
      status: 'Upcoming',
      timing: 'In 5 days',
      icon: Icons.ac_unit_rounded,
    ),
    _ReminderItem(
      title: 'Refrigerator Cleaning',
      location: 'Kitchen',
      date: '28 May 2025',
      status: 'Upcoming',
      timing: 'In 18 days',
      icon: Icons.kitchen_rounded,
    ),
    _ReminderItem(
      title: 'Water Filter Replacement',
      location: 'Kitchen',
      date: '10 May 2025',
      status: 'Overdue',
      timing: '3 days ago',
      icon: Icons.water_drop_outlined,
    ),
    _ReminderItem(
      title: 'Washing Machine Check',
      location: 'Laundry',
      date: '5 Jun 2025',
      status: 'Upcoming',
      timing: 'In 26 days',
      icon: Icons.local_laundry_service_outlined,
    ),
  ];

  _ReminderFilter _selectedFilter = _ReminderFilter.all;

  List<_ReminderItem> get _visibleReminders {
    switch (_selectedFilter) {
      case _ReminderFilter.all:
        return _reminders;
      case _ReminderFilter.upcoming:
        return _reminders
            .where((reminder) => reminder.status == 'Upcoming')
            .toList();
      case _ReminderFilter.overdue:
        return _reminders
            .where((reminder) => reminder.status == 'Overdue')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleReminders = _visibleReminders;

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
      body: SafeArea(
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
                    // UI only: notifications will be connected later.
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
                    label: 'All (8)',
                    isSelected: _selectedFilter == _ReminderFilter.all,
                    onSelected: () {
                      setState(() => _selectedFilter = _ReminderFilter.all);
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _FilterChip(
                    label: 'Upcoming (5)',
                    isSelected: _selectedFilter == _ReminderFilter.upcoming,
                    onSelected: () {
                      setState(
                        () => _selectedFilter = _ReminderFilter.upcoming,
                      );
                    },
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  _FilterChip(
                    label: 'Overdue (2)',
                    isSelected: _selectedFilter == _ReminderFilter.overdue,
                    onSelected: () {
                      setState(() => _selectedFilter = _ReminderFilter.overdue);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            for (var index = 0; index < visibleReminders.length; index++) ...[
              ReminderCard(
                title: visibleReminders[index].title,
                location: visibleReminders[index].location,
                dueDate: visibleReminders[index].date,
                status: visibleReminders[index].status,
                timing: visibleReminders[index].timing,
                applianceIcon: visibleReminders[index].icon,
              ),
              if (index != visibleReminders.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
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
