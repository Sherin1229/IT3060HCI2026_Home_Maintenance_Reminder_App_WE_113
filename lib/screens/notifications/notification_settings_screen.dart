import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _reminderAlerts = true;
  bool _dueDateAlerts = true;
  bool _sound = true;
  bool _emailNotifications = false;
  bool _quietHours = true;
  TimeOfDay _fromTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickTime({required bool isFrom}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromTime = selected;
      } else {
        _toTime = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: 'Back to notifications',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Notification Settings'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              child: Column(
                children: [
                  _SettingSwitch(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device.',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                    },
                  ),
                  const Divider(height: 1),
                  _SettingSwitch(
                    title: 'Reminder Alerts',
                    subtitle:
                        'Get notified about upcoming and overdue reminders.',
                    value: _reminderAlerts,
                    onChanged: (value) {
                      setState(() => _reminderAlerts = value);
                    },
                  ),
                  const Divider(height: 1),
                  _SettingSwitch(
                    title: 'Due-date Alerts',
                    subtitle: 'Notify me before a reminder is due.',
                    value: _dueDateAlerts,
                    onChanged: (value) {
                      setState(() => _dueDateAlerts = value);
                    },
                  ),
                  const Divider(height: 1),
                  _SettingSwitch(
                    title: 'Sound',
                    subtitle: 'Play sound for notifications.',
                    value: _sound,
                    onChanged: (value) => setState(() => _sound = value),
                  ),
                  const Divider(height: 1),
                  _SettingSwitch(
                    title: 'Email Notifications',
                    subtitle: 'Receive important updates via email.',
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    _SettingSwitch(
                      title: 'Quiet Hours',
                      subtitle:
                          'Pause non-critical notifications during these hours.',
                      value: _quietHours,
                      onChanged: (value) {
                        setState(() => _quietHours = value);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimeControl(
                              label: 'From',
                              time: _fromTime,
                              enabled: _quietHours,
                              onTap: () => _pickTime(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeControl(
                              label: 'To',
                              time: _toTime,
                              enabled: _quietHours,
                              onTap: () => _pickTime(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              "You'll still receive critical alerts during quiet hours.",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primaryBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _TimeControl extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  const _TimeControl({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Material(
          color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: enabled
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        time.format(context),
                        style: TextStyle(
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
