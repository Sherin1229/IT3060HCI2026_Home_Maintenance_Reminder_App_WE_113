class NotificationSettingsModel {
  final bool pushNotifications;
  final bool reminderAlerts;
  final bool dueDateAlerts;
  final bool sound;
  final bool emailNotifications;
  final bool quietHours;
  final String quietHoursFrom;
  final String quietHoursTo;

  const NotificationSettingsModel({
    this.pushNotifications = true,
    this.reminderAlerts = true,
    this.dueDateAlerts = true,
    this.sound = true,
    this.emailNotifications = false,
    this.quietHours = true,
    this.quietHoursFrom = '22:00',
    this.quietHoursTo = '07:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'reminderAlerts': reminderAlerts,
      'dueDateAlerts': dueDateAlerts,
      'sound': sound,
      'emailNotifications': emailNotifications,
      'quietHours': quietHours,
      'quietHoursFrom': quietHoursFrom,
      'quietHoursTo': quietHoursTo,
    };
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationSettingsModel();
    return NotificationSettingsModel(
      pushNotifications: map['pushNotifications'] as bool? ?? true,
      reminderAlerts: map['reminderAlerts'] as bool? ?? true,
      dueDateAlerts: map['dueDateAlerts'] as bool? ?? true,
      sound: map['sound'] as bool? ?? true,
      emailNotifications: map['emailNotifications'] as bool? ?? false,
      quietHours: map['quietHours'] as bool? ?? true,
      quietHoursFrom: _validTime(map['quietHoursFrom'], '22:00'),
      quietHoursTo: _validTime(map['quietHoursTo'], '07:00'),
    );
  }

  NotificationSettingsModel copyWith({
    bool? pushNotifications,
    bool? reminderAlerts,
    bool? dueDateAlerts,
    bool? sound,
    bool? emailNotifications,
    bool? quietHours,
    String? quietHoursFrom,
    String? quietHoursTo,
  }) {
    return NotificationSettingsModel(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      reminderAlerts: reminderAlerts ?? this.reminderAlerts,
      dueDateAlerts: dueDateAlerts ?? this.dueDateAlerts,
      sound: sound ?? this.sound,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      quietHours: quietHours ?? this.quietHours,
      quietHoursFrom: quietHoursFrom ?? this.quietHoursFrom,
      quietHoursTo: quietHoursTo ?? this.quietHoursTo,
    );
  }

  static String _validTime(dynamic value, String fallback) {
    final text = value?.toString();
    if (text == null || !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(text)) {
      return fallback;
    }
    return text;
  }

  static String encodeTime({required int hour, required int minute}) {
    final safeHour = hour.clamp(0, 23);
    final safeMinute = minute.clamp(0, 59);
    return '${safeHour.toString().padLeft(2, '0')}:${safeMinute.toString().padLeft(2, '0')}';
  }

  static ({int hour, int minute}) decodeTime(
    String value, {
    required String fallback,
  }) {
    final safeValue = _validTime(value, fallback);
    final parts = safeValue.split(':');
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
