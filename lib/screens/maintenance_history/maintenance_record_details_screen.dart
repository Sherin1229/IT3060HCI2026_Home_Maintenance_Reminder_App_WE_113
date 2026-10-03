import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/maintenance_model.dart';
import '../../providers/maintenance_provider.dart';
import 'maintenance_widgets.dart';

class MaintenanceRecordDetailsScreen extends StatelessWidget {
  final String? recordId;
  const MaintenanceRecordDetailsScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (recordId == null || recordId!.isEmpty || user == null) {
      return const MaintenanceUnavailableScreen();
    }
    return StreamBuilder<MaintenanceRecord?>(
      stream: context.read<MaintenanceProvider>().getRecordById(
        recordId!,
        user.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const MaintenanceUnavailableScreen(
            message: 'Unable to load this maintenance record.',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final record = snapshot.data;
        if (record == null) return const MaintenanceUnavailableScreen();
        return _DetailsView(record: record);
      },
    );
  }
}

class _DetailsView extends StatelessWidget {
  final MaintenanceRecord record;
  const _DetailsView({required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          TextButton(
            onPressed: () => context.push('/maintenance/add', extra: record.id),
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
          if (record.photoUrls.isEmpty)
            const Text(
              'No photos attached.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: record.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _PhotoThumbnail(url: record.photoUrls[index]),
              ),
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
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<MaintenanceProvider>().deleteRecord(
      record.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Maintenance record deleted.'
              : 'Unable to delete maintenance record.',
        ),
      ),
    );
    if (success) context.pop();
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

class _PhotoThumbnail extends StatelessWidget {
  final String url;
  const _PhotoThumbnail({required this.url});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 160,
                child: Center(child: Text('Photo unavailable.')),
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          height: 76,
          width: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: 76,
            width: 76,
            color: const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class MaintenanceUnavailableScreen extends StatelessWidget {
  final String message;
  const MaintenanceUnavailableScreen({
    super.key,
    this.message = 'Maintenance record information is unavailable.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
