import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/maintenance_model.dart';

class MaintenanceStatusPill extends StatelessWidget {
  final MaintenanceStatus status;
  const MaintenanceStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      MaintenanceStatus.completed => (
        'Completed',
        AppColors.success,
        AppColors.successSurface(context),
      ),
      MaintenanceStatus.upcoming => (
        'Upcoming',
        AppColors.primaryBlue,
        AppColors.blueSurface(context),
      ),
      MaintenanceStatus.overdue => (
        'Overdue',
        AppColors.error,
        AppColors.errorSurface(context),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MaintenanceIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const MaintenanceIcon({super.key, required this.icon, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.neutralSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface,
        size: size * .48,
      ),
    );
  }
}

class MaintenanceRecordTile extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback? onTap;
  const MaintenanceRecordTile({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MaintenanceIcon(icon: record.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.appliance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMaintenanceDate(record.scheduledDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              MaintenanceStatusPill(status: record.status),
              const SizedBox(width: 4),
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

class MaintenanceSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const MaintenanceSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}
