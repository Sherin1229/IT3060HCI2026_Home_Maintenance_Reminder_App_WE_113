import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import 'maintenance_models.dart';
import 'maintenance_widgets.dart';

class MaintenanceRecordDetailsScreen extends StatelessWidget {
  final MaintenanceRecord record;
  const MaintenanceRecordDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          TextButton(
            onPressed: () => context.push('/maintenance/add', extra: record),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(child: MaintenanceIcon(icon: record.icon, size: 64)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              record.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              record.appliance,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: MaintenanceStatusPill(status: record.status)),
          const SizedBox(height: 28),
          _DetailRow(
            label: 'Scheduled Date',
            value: formatMaintenanceDate(record.scheduledDate),
          ),
          _DetailRow(
            label: 'Completed Date',
            value: record.completedDate == null
                ? 'Not completed'
                : formatMaintenanceDate(record.completedDate!),
          ),
          _DetailRow(label: 'Cost', value: record.cost ?? 'Not provided'),
          _DetailRow(
            label: 'Service Provider',
            value: record.serviceProvider ?? 'Not provided',
          ),
          const SizedBox(height: 18),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            record.notes ?? 'No notes added.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 22),
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _PhotoPlaceholder(icon: Icons.photo_outlined),
              const SizedBox(width: 10),
              _PhotoPlaceholder(icon: Icons.receipt_long_outlined),
              const SizedBox(width: 10),
              const _PhotoPlaceholder(label: '+3'),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Record'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text(
          'Are you sure you want to delete this maintenance record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record deleted locally.')));
      context.pop();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  final IconData? icon;
  final String? label;
  const _PhotoPlaceholder({this.icon, this.label});
  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    width: 76,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: label != null
          ? Text(
              label!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          : Icon(icon, color: AppColors.textSecondary, size: 28),
    ),
  );
}
