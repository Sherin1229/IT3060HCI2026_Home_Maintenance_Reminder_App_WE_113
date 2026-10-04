import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/maintenance_model.dart';
import '../../providers/maintenance_provider.dart';
import '../../utils/constants.dart';
import 'maintenance_widgets.dart';

class MaintenanceOverviewScreen extends StatelessWidget {
  const MaintenanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _MaintenanceMessage(
        message: 'Please log in to view maintenance records.',
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: StreamBuilder<List<MaintenanceRecord>>(
        stream: context.read<MaintenanceProvider>().getRecords(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _MaintenanceMessage(
              message: 'Unable to load maintenance records.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final upcoming =
              records
                  .where(
                    (record) => record.status == MaintenanceStatus.upcoming,
                  )
                  .toList()
                ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          final overdue =
              records
                  .where((record) => record.status == MaintenanceStatus.overdue)
                  .toList()
                ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _SummaryGrid(records: records),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/maintenance/history'),
                icon: const Icon(Icons.history_rounded),
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('View Maintenance History'),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              MaintenanceSectionHeader(
                title: 'Upcoming Maintenance',
                onViewAll: () => context.push('/maintenance/history'),
              ),
              if (upcoming.isEmpty)
                const _SectionEmpty(message: 'No upcoming maintenance.'),
              ...upcoming.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OverviewRecordCard(
                    record: record,
                    onTap: () =>
                        context.push('/maintenance/complete', extra: record.id),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MaintenanceSectionHeader(
                title: 'Overdue Maintenance',
                onViewAll: () => context.push('/maintenance/history'),
              ),
              if (overdue.isEmpty)
                const _SectionEmpty(message: 'No overdue maintenance.'),
              ...overdue.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OverviewRecordCard(
                    record: record,
                    onTap: () =>
                        context.push('/maintenance/details', extra: record.id),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/maintenance/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Maintenance Record'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<MaintenanceRecord> records;
  const _SummaryGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        records.length.toString(),
        'Total Tasks',
        Icons.list_alt_rounded,
        AppColors.primaryBlue,
      ),
      (
        records
            .where((record) => record.status == MaintenanceStatus.completed)
            .length
            .toString(),
        'Completed',
        Icons.check_circle,
        AppColors.success,
      ),
      (
        records
            .where((record) => record.status == MaintenanceStatus.upcoming)
            .length
            .toString(),
        'Upcoming',
        Icons.schedule_rounded,
        AppColors.primaryBlue,
      ),
      (
        records
            .where((record) => record.status == MaintenanceStatus.overdue)
            .length
            .toString(),
        'Overdue',
        Icons.error_rounded,
        AppColors.error,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final (value, label, icon, color) = values[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewRecordCard extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback onTap;
  const _OverviewRecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = record.status == MaintenanceStatus.overdue;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MaintenanceIcon(icon: record.icon, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.appliance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Due: ${formatMaintenanceDate(record.scheduledDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                overdue ? 'Overdue' : _relativeDueLabel(record.scheduledDate),
                style: TextStyle(
                  fontSize: 11,
                  color: overdue ? AppColors.error : AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeDueLabel(DateTime date) {
  final days = DateUtils.dateOnly(
    date,
  ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}

class _SectionEmpty extends StatelessWidget {
  final String message;
  const _SectionEmpty({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _MaintenanceMessage extends StatelessWidget {
  final String message;
  const _MaintenanceMessage({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
