import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/appliance_model.dart';
import '../../models/maintenance_model.dart';
import '../../models/reminder_model.dart';
import '../../providers/appliance_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/user_service.dart';
import '../../services/warranty_service.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Homeowner';
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view your dashboard.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final userService = UserService();
    final warrantyService = WarrantyService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: userService.watchUserProfile(user.uid),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data;
            final firstName = _getFirstName(userData?['fullName']);
            final photoUrl = userData?['photoUrl'] as String?;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dashboard Header (Greeting + User Photo + Top Right Notification Bell)
                  _buildHeader(context, user.uid, firstName, photoUrl),
                  const SizedBox(height: 20),

                  // 2. Greeting Headline
                  Text(
                    'Hello, $firstName!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your home is running smoothly.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Home at a Glance Section Header & 2x2 Grid Cards
                  Text(
                    'Your Home at a Glance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2x2 Statistics Grid
                  _buildHomeAtAGlanceGrid(
                    context,
                    userId: user.uid,
                    warrantyService: warrantyService,
                  ),
                  const SizedBox(height: 24),

                  // 4. Upcoming Maintenance Section
                  _buildUpcomingMaintenanceSection(context, user.uid),
                  const SizedBox(height: 20),

                  // 5. Expiring Warranty Summary Card
                  _buildExpiringWarrantyCard(
                    context,
                    userId: user.uid,
                    warrantyService: warrantyService,
                  ),
                  const SizedBox(height: 24),

                  // 6. Quick Action Buttons Row (Add Appliance, Add Reminder)
                  _buildQuickActionButtons(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Dashboard Header with Greeting, Logo/Profile Image, and Top Right Notification Bell
  Widget _buildHeader(
    BuildContext context,
    String userId,
    String firstName,
    String? photoUrl,
  ) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            // User profile photo or brand logo fallback
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueSurface(context),
                border: Border.all(
                  color: AppColors.primaryBlue.withAlpha(50),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryBlue,
                            ),
                      )
                    : Center(
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'H',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimeOfDayGreeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'HomiQ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),

        // TOP RIGHT NOTIFICATION BELL
        StreamBuilder<int>(
          stream: notificationProvider.watchUnreadCount(userId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () {
                    context.push('/notifications');
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// 2x2 Grid Cards: Total Appliances, Upcoming, Overdue, Expiring Warranties
  Widget _buildHomeAtAGlanceGrid(
    BuildContext context, {
    required String userId,
    required WarrantyService warrantyService,
  }) {
    final applianceProvider = context.read<ApplianceProvider>();
    final reminderProvider = context.read<ReminderProvider>();

    return StreamBuilder<List<ApplianceModel>>(
      stream: applianceProvider.getUserAppliances(userId),
      builder: (context, applianceSnapshot) {
        final totalAppliances = applianceSnapshot.data?.length ?? 0;

        return StreamBuilder<List<ReminderModel>>(
          stream: reminderProvider.getReminders(userId),
          builder: (context, reminderSnapshot) {
            final reminders = reminderSnapshot.data ?? [];
            final today = DateUtils.dateOnly(DateTime.now());

            final upcomingReminders = reminders.where((r) {
              if (r.isCompleted) return false;
              final rDate = DateUtils.dateOnly(r.date);
              return !rDate.isBefore(today);
            }).length;

            final overdueReminders = reminders.where((r) {
              if (r.isCompleted) return false;
              final rDate = DateUtils.dateOnly(r.date);
              return rDate.isBefore(today);
            }).length;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: warrantyService.getUserWarranties(userId),
              builder: (context, warrantySnapshot) {
                final warrantyDocs = warrantySnapshot.data?.docs ?? [];
                int expiringWarrantiesCount = 0;

                for (final doc in warrantyDocs) {
                  final data = doc.data();
                  final endDateValue = data['warrantyEndDate'];
                  if (endDateValue is Timestamp) {
                    final endDate = DateUtils.dateOnly(endDateValue.toDate());
                    final daysLeft = endDate.difference(today).inDays;
                    if (daysLeft >= 0 && daysLeft <= 30) {
                      expiringWarrantiesCount++;
                    }
                  }
                }

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Total Appliances',
                      count: '$totalAppliances',
                      icon: Icons.kitchen_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: AppColors.primaryBlue,
                      onTap: () => context.go('/appliances'),
                    ),
                    _buildStatCard(
                      context,
                      title: 'Upcoming',
                      count: '$upcomingReminders',
                      icon: Icons.event_note_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      onTap: () => context.go('/reminders'),
                    ),
                    _buildStatCard(
                      context,
                      title: 'Overdue',
                      count: '$overdueReminders',
                      icon: Icons.warning_amber_rounded,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: AppColors.error,
                      onTap: () => context.go('/reminders'),
                    ),
                    _buildStatCard(
                      context,
                      title: 'Expiring Warranties',
                      count: '$expiringWarrantiesCount',
                      icon: Icons.verified_outlined,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: AppColors.success,
                      onTap: () => context.go('/warranties'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Upcoming Maintenance Section
  Widget _buildUpcomingMaintenanceSection(BuildContext context, String userId) {
    final maintenanceProvider = context.read<MaintenanceProvider>();

    return StreamBuilder<List<MaintenanceRecord>>(
      stream: maintenanceProvider.getUserMaintenanceRecords(userId),
      builder: (context, snapshot) {
        final allRecords = snapshot.data ?? [];
        final upcomingList = allRecords.where((m) {
          return m.completedDate == null;
        }).toList();

        // Sort by scheduledDate ascending
        upcomingList.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

        final topRecords = upcomingList.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Maintenance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/maintenance'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (topRecords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming maintenance tasks.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: topRecords.map((record) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppColors.blueSurface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            record.icon,
                            color: AppColors.primaryBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.appliance.isNotEmpty
                                    ? record.appliance
                                    : 'Home Maintenance',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: record.status == MaintenanceStatus.overdue
                                ? AppColors.errorSurface(context)
                                : AppColors.blueSurface(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            formatMaintenanceDate(record.scheduledDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: record.status == MaintenanceStatus.overdue
                                  ? AppColors.error
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  /// Expiring Warranty Summary Card
  Widget _buildExpiringWarrantyCard(
    BuildContext context, {
    required String userId,
    required WarrantyService warrantyService,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: warrantyService.getUserWarranties(userId),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int count = 0;

        for (final doc in docs) {
          final data = doc.data();
          final endDateValue = data['warrantyEndDate'];
          if (endDateValue is Timestamp) {
            final endDate = DateUtils.dateOnly(endDateValue.toDate());
            final daysLeft = endDate.difference(today).inDays;
            if (daysLeft >= 0 && daysLeft <= 30) {
              count++;
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: () => context.go('/warranties'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppColors.warningSurface(context)
                          : AppColors.successSurface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      count > 0
                          ? Icons.shield_outlined
                          : Icons.verified_user_rounded,
                      color: count > 0 ? AppColors.warning : AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count > 0
                              ? '$count ${count == 1 ? 'Warranty' : 'Warranties'} Expiring'
                              : 'All Warranties Up to Date',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count > 0
                              ? 'Review before next month'
                              : 'No action required right now',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Quick Action Buttons: Add Appliance, Add Reminder
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/appliances/add'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryOutline(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text(
                'Add Appliance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/reminders/create'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryOutline(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.alarm_add_rounded, size: 18),
              label: const Text(
                'Add Reminder',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
