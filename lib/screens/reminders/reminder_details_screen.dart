import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/constants.dart';

enum _ReminderMenuAction { edit, delete }

class ReminderDetailsScreen extends StatefulWidget {
  final String reminderId;

  const ReminderDetailsScreen({super.key, required this.reminderId});

  @override
  State<ReminderDetailsScreen> createState() => _ReminderDetailsScreenState();
}

class _ReminderDetailsScreenState extends State<ReminderDetailsScreen> {
  bool _isCompleting = false;
  bool _isDeleting = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openEditReminder() {
    context.push('/reminders/edit', extra: widget.reminderId);
  }

  Future<void> _confirmCompletion(ReminderModel reminder) async {
    if (reminder.isCompleted || _isCompleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: const Text(
          'Are you sure you want to mark this reminder as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to update this reminder.');
      return;
    }
    setState(() => _isCompleting = true);
    final provider = context.read<ReminderProvider>();
    final success = await provider.markReminderCompleted(
      widget.reminderId,
      user.uid,
    );
    if (!mounted) return;
    setState(() => _isCompleting = false);
    _showMessage(
      success
          ? 'Reminder marked as completed.'
          : provider.errorMessage ?? 'Unable to update reminder.',
    );
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Delete Reminder?',
                  style: Theme.of(dialogContext).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete this reminder? This action cannot be undone.',
                  style: Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.surface,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('You must be logged in to delete this reminder.');
      return;
    }
    setState(() => _isDeleting = true);
    final provider = context.read<ReminderProvider>();
    final success = await provider.deleteReminder(widget.reminderId, user.uid);
    if (!mounted) return;
    if (success) {
      _showMessage('Reminder deleted successfully.');
      context.go('/reminders');
    } else {
      setState(() => _isDeleting = false);
      _showMessage(provider.errorMessage ?? 'Unable to delete reminder.');
    }
  }

  void _handleMenu(_ReminderMenuAction action) {
    if (action == _ReminderMenuAction.edit) {
      _openEditReminder();
    } else {
      _confirmDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to reminders',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Reminder Details'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_ReminderMenuAction>(
            tooltip: 'Reminder options',
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ReminderMenuAction.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: _ReminderMenuAction.delete,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view this reminder.'))
          : StreamBuilder<ReminderModel?>(
              stream: context.read<ReminderProvider>().getReminderById(
                widget.reminderId,
                user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load reminder.'));
                }
                final reminder = snapshot.data;
                if (reminder == null) {
                  return const Center(
                    child: Text('Reminder information is unavailable.'),
                  );
                }
                return _DetailsBody(
                  reminder: reminder,
                  isBusy: _isCompleting || _isDeleting,
                  onComplete: () => _confirmCompletion(reminder),
                  onEdit: _openEditReminder,
                  onDelete: _confirmDelete,
                );
              },
            ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final ReminderModel reminder;
  final bool isBusy;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailsBody({
    required this.reminder,
    required this.isBusy,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  String get status {
    if (reminder.isCompleted) return 'Completed';
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(reminder.date).isBefore(today)
        ? 'Overdue'
        : 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final notes = reminder.notes?.trim();
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SummaryCard(reminder: reminder, status: status),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notes == null || notes.isEmpty ? 'No notes added' : notes,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Text('Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _ReminderDetailsCard(reminder: reminder),
              ],
            ),
          ),
          _DetailActions(
            isCompleted: reminder.isCompleted,
            isBusy: isBusy,
            onComplete: onComplete,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ReminderModel reminder;
  final String status;

  const _SummaryCard({required this.reminder, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Overdue'
        ? AppColors.error
        : status == 'Completed'
        ? AppColors.success
        : AppColors.primaryBlue;
    final statusBackground = status == 'Overdue'
        ? const Color(0xFFFEE2E2)
        : status == 'Completed'
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFDBEAFE);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(reminder.category),
                color: AppColors.primaryBlue,
                size: 38,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reminder.location.trim().isEmpty
                              ? 'Not specified'
                              : reminder.location,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderDetailsCard extends StatelessWidget {
  final ReminderModel reminder;

  const _ReminderDetailsCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final details = [
      (
        Icons.calendar_today_outlined,
        'Next Reminder Date',
        MaterialLocalizations.of(context).formatMediumDate(reminder.date),
      ),
      (
        Icons.access_time_rounded,
        'Time',
        reminder.time?.trim().isNotEmpty == true ? reminder.time! : 'Not set',
      ),
      (Icons.repeat_rounded, 'Frequency', reminder.frequency),
      (Icons.sell_outlined, 'Category', reminder.category),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < details.length; index++) ...[
              _DetailRow(
                icon: details[index].$1,
                label: details[index].$2,
                value: details[index].$3,
              ),
              if (index != details.length - 1)
                const Divider(height: 1, indent: 46),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 24),
          const SizedBox(width: 18),
          Expanded(
            flex: 3,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  final bool isCompleted;
  final bool isBusy;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailActions({
    required this.isCompleted,
    required this.isBusy,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: isCompleted || isBusy ? null : onComplete,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(isCompleted ? 'Completed' : 'Mark as Completed'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'HVAC' => Icons.ac_unit_rounded,
    'Refrigerator' => Icons.kitchen_rounded,
    'Water Filter' => Icons.water_drop_outlined,
    'Washing Machine' => Icons.local_laundry_service_outlined,
    'Electrical' => Icons.electrical_services_rounded,
    'Plumbing' => Icons.plumbing_rounded,
    _ => Icons.build_outlined,
  };
}
