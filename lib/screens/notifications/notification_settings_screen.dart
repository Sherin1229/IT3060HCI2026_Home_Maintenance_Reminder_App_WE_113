import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/notification_settings_model.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettingsModel? _settings;

  TimeOfDay _timeFrom(String value, String fallback) {
    final decoded = NotificationSettingsModel.decodeTime(
      value,
      fallback: fallback,
    );
    return TimeOfDay(hour: decoded.hour, minute: decoded.minute);
  }

  String _timeToString(TimeOfDay value) {
    return NotificationSettingsModel.encodeTime(
      hour: value.hour,
      minute: value.minute,
    );
  }

  Future<void> _saveSettings(NotificationSettingsModel next) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final previous = _settings;
    setState(() => _settings = next);
    final provider = context.read<NotificationProvider>();
    final success = await provider.saveSettings(user.uid, next);
    if (!mounted || success) return;
    setState(() => _settings = previous);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to save notification settings.',
          ),
        ),
      );
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final settings = _settings;
    if (settings == null || !settings.quietHours) return;
    final fromTime = _timeFrom(settings.quietHoursFrom, '22:00');
    final toTime = _timeFrom(settings.quietHoursTo, '07:00');
    final selected = await showTimePicker(
      context: context,
      initialTime: isFrom ? fromTime : toTime,
    );
    if (selected == null || !mounted) return;
    await _saveSettings(
      isFrom
          ? settings.copyWith(quietHoursFrom: _timeToString(selected))
          : settings.copyWith(quietHoursTo: _timeToString(selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
      body: user == null
          ? const Center(
              child: Text('Please log in to manage notification settings.'),
            )
          : StreamBuilder<NotificationSettingsModel>(
              stream: context.read<NotificationProvider>().getSettings(
                user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _settings == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && _settings == null) {
                  return const Center(
                    child: Text('Unable to load notification settings.'),
                  );
                }
                _settings ??=
                    snapshot.data ?? const NotificationSettingsModel();
                return _buildSettings(_settings!);
              },
            ),
    );
  }

  Widget _buildSettings(NotificationSettingsModel settings) {
    final fromTime = _timeFrom(settings.quietHoursFrom, '22:00');
    final toTime = _timeFrom(settings.quietHoursTo, '07:00');
    return SafeArea(
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
                  value: settings.pushNotifications,
                  onChanged: (value) => _saveSettings(
                    settings.copyWith(pushNotifications: value),
                  ),
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Reminder Alerts',
                  subtitle:
                      'Get notified about upcoming and overdue reminders.',
                  value: settings.reminderAlerts,
                  onChanged: (value) =>
                      _saveSettings(settings.copyWith(reminderAlerts: value)),
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Due-date Alerts',
                  subtitle: 'Notify me before a reminder is due.',
                  value: settings.dueDateAlerts,
                  onChanged: (value) =>
                      _saveSettings(settings.copyWith(dueDateAlerts: value)),
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications.',
                  value: settings.sound,
                  onChanged: (value) =>
                      _saveSettings(settings.copyWith(sound: value)),
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Email Notifications',
                  subtitle: 'Receive important updates via email.',
                  value: settings.emailNotifications,
                  onChanged: (value) => _saveSettings(
                    settings.copyWith(emailNotifications: value),
                  ),
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
                    value: settings.quietHours,
                    onChanged: (value) =>
                        _saveSettings(settings.copyWith(quietHours: value)),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TimeControl(
                            label: 'From',
                            time: fromTime,
                            enabled: settings.quietHours,
                            onTap: () => _pickTime(isFrom: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeControl(
                            label: 'To',
                            time: toTime,
                            enabled: settings.quietHours,
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
