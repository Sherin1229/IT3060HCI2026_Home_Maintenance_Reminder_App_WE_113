import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import 'maintenance_models.dart';
import 'maintenance_widgets.dart';

class MaintenanceOverviewScreen extends StatelessWidget {
  const MaintenanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = maintenanceRecords
        .where((record) => record.status == MaintenanceStatus.upcoming)
        .toList();
    final overdue = maintenanceRecords
        .where((record) => record.status == MaintenanceStatus.overdue)
        .toList();
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _SummaryGrid(),
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
          ...upcoming.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OverviewRecordCard(
                record: record,
                onTap: () =>
                    context.push('/maintenance/complete', extra: record),
              ),
            ),
          ),
          const SizedBox(height: 8),
          MaintenanceSectionHeader(
            title: 'Overdue Maintenance',
            onViewAll: () => context.push('/maintenance/history'),
          ),
          ...overdue.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OverviewRecordCard(
                record: record,
                onTap: () =>
                    context.push('/maintenance/details', extra: record),
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
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    const values = [
      ('12', 'Total Tasks', Icons.list_alt_rounded, AppColors.primaryBlue),
      ('8', 'Completed', Icons.check_circle, AppColors.success),
      ('3', 'Upcoming', Icons.schedule_rounded, AppColors.primaryBlue),
      ('1', 'Overdue', Icons.error_rounded, AppColors.error),
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
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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
    final isOverdue = record.status == MaintenanceStatus.overdue;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Due: ${formatMaintenanceDate(record.scheduledDate)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isOverdue ? 'Overdue' : 'In 12 days',
                style: TextStyle(
                  fontSize: 11,
                  color: isOverdue ? AppColors.error : AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
