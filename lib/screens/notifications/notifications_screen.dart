import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';

enum _NotificationFilter { all, unread, system }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  List<NotificationModel> _visibleNotifications(
    List<NotificationModel> notifications,
  ) {
    return switch (_selectedFilter) {
      _NotificationFilter.all => notifications,
      _NotificationFilter.unread =>
        notifications.where((item) => !item.isRead).toList(),
      _NotificationFilter.system =>
        notifications.where((item) => item.isSystem).toList(),
    };
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final provider = context.read<NotificationProvider>();
    final success = await provider.markAsRead(notification.id, user.uid);
    if (!success && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Unable to update notification.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
      body: user == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<List<NotificationModel>>(
              stream: context.read<NotificationProvider>().getNotifications(
                user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load notifications.'),
                  );
                }
                return _buildNotificationList(snapshot.data ?? const []);
              },
            ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    final visible = _visibleNotifications(notifications);
    final unreadCount = notifications.where((item) => !item.isRead).length;
    final systemCount = notifications.where((item) => item.isSystem).length;
    return SafeArea(
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
                  label: 'All (${notifications.length})',
                  selected: _selectedFilter == _NotificationFilter.all,
                  onTap: () =>
                      setState(() => _selectedFilter = _NotificationFilter.all),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  label: 'Unread ($unreadCount)',
                  selected: _selectedFilter == _NotificationFilter.unread,
                  onTap: () => setState(
                    () => _selectedFilter = _NotificationFilter.unread,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  label: 'System ($systemCount)',
                  selected: _selectedFilter == _NotificationFilter.system,
                  onTap: () => setState(
                    () => _selectedFilter = _NotificationFilter.system,
                  ),
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
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = _presentationFor(notification.type);
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
                  color: presentation.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(presentation.icon, color: presentation.color),
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
                    _relativeTime(notification.createdAt),
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

({IconData icon, Color color}) _presentationFor(String type) {
  return switch (type.toLowerCase()) {
    'reminder' => (icon: Icons.alarm_rounded, color: AppColors.primaryBlue),
    'warranty' => (
      icon: Icons.verified_user_outlined,
      color: AppColors.warning,
    ),
    'maintenance' => (icon: Icons.build_outlined, color: AppColors.success),
    'system' => (icon: Icons.home_outlined, color: AppColors.primaryBlue),
    _ => (icon: Icons.notifications_outlined, color: AppColors.secondaryTeal),
  };
}

String _relativeTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
