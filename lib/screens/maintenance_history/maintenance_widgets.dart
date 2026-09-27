import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'maintenance_models.dart';

class MaintenanceStatusPill extends StatelessWidget {
  final MaintenanceStatus status;
  const MaintenanceStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      MaintenanceStatus.completed => (
        'Completed',
        AppColors.success,
        const Color(0xFFE9F9EF),
      ),
      MaintenanceStatus.upcoming => (
        'Upcoming',
        AppColors.primaryBlue,
        const Color(0xFFEAF2FF),
      ),
      MaintenanceStatus.overdue => (
        'Overdue',
        AppColors.error,
        const Color(0xFFFFECEF),
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: size * .48),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.appliance,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMaintenanceDate(record.scheduledDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              MaintenanceStatusPill(status: record.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
