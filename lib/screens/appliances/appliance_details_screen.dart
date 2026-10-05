import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/appliance_model.dart';
import '../../models/maintenance_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/appliance_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/warranty_service.dart';
import '../../utils/constants.dart';

class ApplianceDetailsScreen extends StatefulWidget {
  final String? applianceId;
  final ApplianceModel? appliance;

  const ApplianceDetailsScreen({super.key, this.applianceId, this.appliance});

  @override
  State<ApplianceDetailsScreen> createState() => _ApplianceDetailsScreenState();
}

class _ApplianceDetailsScreenState extends State<ApplianceDetailsScreen> {
  int _selectedTabIndex = 0;

  void _showDeleteConfirmationDialog(ApplianceModel appliance) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Appliance?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${appliance.applianceName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final success = await context
                    .read<ApplianceProvider>()
                    .deleteAppliance(
                      applianceId: appliance.id,
                      userId: user.uid,
                    );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appliance deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete appliance.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveId = widget.applianceId ?? widget.appliance?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primaryBlue,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Appliance Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<ApplianceModel?>(
          stream: context.read<ApplianceProvider>().getApplianceById(
            effectiveId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                widget.appliance == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final appliance = snapshot.data ?? widget.appliance;

            if (appliance == null) {
              return const Center(child: Text('Appliance details not found.'));
            }

            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return const Center(
                child: Text('Please log in to view appliance details.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Appliance Info Card
                  _buildMainApplianceCard(context, appliance),
                  const SizedBox(height: 16),

                  _buildWarrantySection(context, appliance.id, user.uid),
                  const SizedBox(height: 16),

                  // Maintenance & Reminders Section (Tabs)
                  _buildMaintenanceSectionCard(context, appliance.id, user.uid),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainApplianceCard(
    BuildContext context,
    ApplianceModel appliance,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appliance Photo / Visual Box
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.blueSurface(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    appliance.photoUrl != null && appliance.photoUrl!.isNotEmpty
                    ? Image.network(
                        appliance.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              appliance.categoryIcon,
                              size: 64,
                              color: AppColors.primaryBlue,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          appliance.categoryIcon,
                          size: 64,
                          color: AppColors.primaryBlue,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appliance.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Appliance Title & Brand
            Text(
              appliance.applianceName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${appliance.brand} ${appliance.modelNumber}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // 2-Column Info Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridLabel('Brand'),
                      const SizedBox(height: 2),
                      _buildGridValue(appliance.brand),
                      const SizedBox(height: 12),
                      _buildGridLabel('Purchase Date'),
                      const SizedBox(height: 2),
                      _buildGridValue(_formatDate(appliance.purchaseDate)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridLabel('Model No.'),
                      const SizedBox(height: 2),
                      _buildGridValue(appliance.modelNumber),
                      const SizedBox(height: 12),
                      _buildGridLabel('Serial No.'),
                      const SizedBox(height: 2),
                      _buildGridValue(
                        appliance.serialNumber ?? 'Not specified',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Appliance management actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/appliances/edit', extra: appliance);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  height: 44,
                  width: 44,
                  child: IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(appliance),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantySection(
    BuildContext context,
    String applianceId,
    String userId,
  ) {
    return StreamBuilder(
      stream: WarrantyService().getUserWarranties(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return const _LinkedSectionMessage(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load linked warranty',
          );
        }
        final documents = (snapshot.data?.docs ?? const [])
            .where((document) => document.data()['applianceId'] == applianceId)
            .toList();
        if (documents.isEmpty) {
          return const _LinkedSectionMessage(
            icon: Icons.verified_user_outlined,
            title: 'No warranty linked to this appliance',
          );
        }
        documents.sort((a, b) {
          final aDate = a.data()['warrantyEndDate'];
          final bDate = b.data()['warrantyEndDate'];
          final aValue = aDate is Timestamp ? aDate.toDate() : DateTime(9999);
          final bValue = bDate is Timestamp ? bDate.toDate() : DateTime(9999);
          return aValue.compareTo(bValue);
        });
        final document = documents.first;
        final data = document.data();
        final endDateValue = data['warrantyEndDate'];
        final endDate = endDateValue is Timestamp
            ? endDateValue.toDate()
            : endDateValue is DateTime
            ? endDateValue
            : null;
        final provider = data['provider']?.toString().trim();
        final today = DateUtils.dateOnly(DateTime.now());
        final normalizedEnd = endDate == null
            ? null
            : DateUtils.dateOnly(endDate);
        final daysLeft = normalizedEnd?.difference(today).inDays;
        final status = daysLeft == null
            ? 'Unknown'
            : daysLeft < 0
            ? 'Expired'
            : daysLeft <= 30
            ? 'Expiring Soon'
            : 'Active';
        final statusColor = status == 'Expired'
            ? Theme.of(context).colorScheme.error
            : status == 'Expiring Soon'
            ? AppColors.warningText(context)
            : status == 'Active'
            ? AppColors.successText(context)
            : Theme.of(context).colorScheme.onSurfaceVariant;
        final statusBackground = status == 'Expired'
            ? AppColors.errorSurface(context)
            : status == 'Expiring Soon'
            ? AppColors.warningSurface(context)
            : status == 'Active'
            ? AppColors.successSurface(context)
            : AppColors.neutralSurface(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warranty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  provider == null || provider.isEmpty
                      ? 'Provider not specified'
                      : provider,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endDate == null
                      ? 'Expiry date unavailable'
                      : 'Expires ${_formatDate(endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/warranties/details', extra: document.id),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(
                    data['documentUrl']?.toString().trim().isNotEmpty == true
                        ? 'View Policy Document'
                        : 'View Warranty Details',
                  ),
                ),
                if (documents.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${documents.length} linked warranties',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceSectionCard(
    BuildContext context,
    String applianceId,
    String userId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTabItem(0, 'Upcoming'),
              const SizedBox(width: 24),
              _buildTabItem(1, 'History'),
              const SizedBox(width: 24),
              _buildTabItem(2, 'Manuals'),
            ],
          ),
          const Divider(height: 16),

          if (_selectedTabIndex == 0)
            _buildUpcomingContent(context, applianceId, userId),
          if (_selectedTabIndex == 1)
            _buildHistoryContent(context, applianceId, userId),
          if (_selectedTabIndex == 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No user manuals or guides uploaded.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingContent(
    BuildContext context,
    String applianceId,
    String userId,
  ) {
    return StreamBuilder<List<ReminderModel>>(
      stream: context.read<ReminderProvider>().getReminders(userId),
      builder: (context, reminderSnapshot) {
        return StreamBuilder<List<MaintenanceRecord>>(
          stream: context.read<MaintenanceProvider>().getRecords(userId),
          builder: (context, maintenanceSnapshot) {
            if ((reminderSnapshot.connectionState == ConnectionState.waiting &&
                    !reminderSnapshot.hasData) ||
                (maintenanceSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !maintenanceSnapshot.hasData)) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (reminderSnapshot.hasError || maintenanceSnapshot.hasError) {
              return const _InlineEmptyState(
                icon: Icons.error_outline_rounded,
                message: 'Unable to load linked activity.',
              );
            }
            final today = DateUtils.dateOnly(DateTime.now());
            final reminders = (reminderSnapshot.data ?? const [])
                .where(
                  (item) =>
                      item.applianceId == applianceId &&
                      !item.isCompleted &&
                      !DateUtils.dateOnly(item.date).isBefore(today),
                )
                .toList();
            final maintenance = (maintenanceSnapshot.data ?? const [])
                .where(
                  (item) =>
                      item.applianceId == applianceId &&
                      item.status == MaintenanceStatus.upcoming,
                )
                .toList();
            if (reminders.isEmpty && maintenance.isEmpty) {
              return const _InlineEmptyState(
                icon: Icons.event_available_outlined,
                message: 'No upcoming reminders or maintenance.',
              );
            }
            return Column(
              children: [
                for (final reminder in reminders)
                  _LinkedActivityTile(
                    icon: Icons.alarm_outlined,
                    title: reminder.title,
                    subtitle: _formatDate(reminder.date),
                    onTap: () =>
                        context.push('/reminders/details', extra: reminder.id),
                  ),
                for (final record in maintenance)
                  _LinkedActivityTile(
                    icon: record.icon,
                    title: record.title,
                    subtitle: _formatDate(record.scheduledDate),
                    onTap: () =>
                        context.push('/maintenance/details', extra: record.id),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryContent(
    BuildContext context,
    String applianceId,
    String userId,
  ) {
    return StreamBuilder<List<MaintenanceRecord>>(
      stream: context.read<MaintenanceProvider>().getRecords(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const _InlineEmptyState(
            icon: Icons.error_outline_rounded,
            message: 'Unable to load maintenance history.',
          );
        }
        final records = (snapshot.data ?? const [])
            .where(
              (item) =>
                  item.applianceId == applianceId &&
                  item.status == MaintenanceStatus.completed,
            )
            .toList();
        if (records.isEmpty) {
          return const _InlineEmptyState(
            icon: Icons.history_toggle_off_rounded,
            message: 'No linked maintenance history.',
          );
        }
        return Column(
          children: [
            for (final record in records)
              _LinkedActivityTile(
                icon: record.icon,
                title: record.title,
                subtitle: _formatDate(
                  record.completedDate ?? record.scheduledDate,
                ),
                onTap: () =>
                    context.push('/maintenance/details', extra: record.id),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryBlue
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildGridLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildGridValue(String value) {
    return Text(
      value,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }
}

class _LinkedSectionMessage extends StatelessWidget {
  final IconData icon;
  final String title;

  const _LinkedSectionMessage({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LinkedActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkedActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
