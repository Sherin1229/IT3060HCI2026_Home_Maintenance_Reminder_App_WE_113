import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

enum _NotificationFilter { all, unread, system }

class _NotificationItem {
  final String title;
  final String message;
  final String timestamp;
  final IconData icon;
  final Color accent;
  final bool isSystem;
  bool isRead;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.accent,
    required this.isSystem,
    required this.isRead,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: 'AC Service due soon',
      message: 'Your AC Service is due in 5 days.',
      timestamp: '2h ago',
      icon: Icons.ac_unit_rounded,
      accent: AppColors.primaryBlue,
      isSystem: false,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Water Filter Replacement overdue',
      message: 'This maintenance reminder was due 3 days ago.',
      timestamp: '1d ago',
      icon: Icons.water_drop_outlined,
      accent: AppColors.error,
      isSystem: false,
      isRead: true,
    ),
    _NotificationItem(
      title: 'Warranty expiring soon',
      message: 'Your Washing Machine warranty expires in 18 days.',
      timestamp: '1d ago',
      icon: Icons.verified_user_outlined,
      accent: AppColors.warning,
      isSystem: false,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Reminder completed',
      message: 'Kitchen Chimney Cleaning was marked as completed.',
      timestamp: '3d ago',
      icon: Icons.check_circle_outline_rounded,
      accent: AppColors.success,
      isSystem: false,
      isRead: true,
    ),
    _NotificationItem(
      title: 'Maintenance record added',
      message: 'A maintenance record was added for your Refrigerator.',
      timestamp: '3d ago',
      icon: Icons.add_circle_outline_rounded,
      accent: AppColors.primaryBlue,
      isSystem: false,
      isRead: true,
    ),
    _NotificationItem(
      title: 'Welcome to HomiQ!',
      message: "Let's keep your home maintenance organized.",
      timestamp: '3d ago',
      icon: Icons.home_outlined,
      accent: AppColors.primaryBlue,
      isSystem: true,
      isRead: true,
    ),
  ];

  List<_NotificationItem> get _visibleNotifications {
    return switch (_selectedFilter) {
      _NotificationFilter.all => _notifications,
      _NotificationFilter.unread =>
        _notifications.where((item) => !item.isRead).toList(),
      _NotificationFilter.system =>
        _notifications.where((item) => item.isSystem).toList(),
    };
  }

  int get _unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  int get _systemCount =>
      _notifications.where((notification) => notification.isSystem).length;

  void _markAsRead(_NotificationItem notification) {
    if (notification.isRead) return;
    setState(() => notification.isRead = true);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleNotifications;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to dashboard',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications/settings'),
            tooltip: 'Notification settings',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              "Here's what's happening with your home.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'All (${_notifications.length})',
                    selected: _selectedFilter == _NotificationFilter.all,
                    onTap: () {
                      setState(() => _selectedFilter = _NotificationFilter.all);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'Unread ($_unreadCount)',
                    selected: _selectedFilter == _NotificationFilter.unread,
                    onTap: () {
                      setState(
                        () => _selectedFilter = _NotificationFilter.unread,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterButton(
                    label: 'System ($_systemCount)',
                    selected: _selectedFilter == _NotificationFilter.system,
                    onTap: () {
                      setState(
                        () => _selectedFilter = _NotificationFilter.system,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            if (visible.isEmpty)
              const _EmptyNotifications()
            else
              for (final notification in visible) ...[
                _NotificationCard(
                  notification: notification,
                  onTap: () => _markAsRead(notification),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.surface : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: notification.isRead ? AppColors.surface : const Color(0xFFF8FBFF),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notification.icon, color: notification.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    notification.timestamp,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.circle,
                      size: 9,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications in this category.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
