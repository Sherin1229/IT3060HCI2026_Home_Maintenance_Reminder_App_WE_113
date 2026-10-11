import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_settings_model.dart';
import '../models/reminder_model.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification payloads are displayed by Android while the app is in the
  // background. Data-only delivery requires a trusted sender/backend.
}

class DeviceNotificationService {
  DeviceNotificationService._();

  static final DeviceNotificationService instance =
      DeviceNotificationService._();

  static const _channelId = 'homiq_due_alerts';
  static const _channelName = 'HomiQ alerts';
  static const _channelDescription =
      'Maintenance reminder and warranty expiry alerts.';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _registeredToken;
  bool _initialized = false;
  void Function(String route, Object? extra)? _onOpenRoute;

  Future<void> initialize({
    void Function(String route, Object? extra)? onOpenRoute,
  }) async {
    if (_initialized) {
      _onOpenRoute = onOpenRoute ?? _onOpenRoute;
      return;
    }
    _onOpenRoute = onOpenRoute;

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      debugPrint('Unable to configure local timezone: $error');
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);
    _messaging.onTokenRefresh.listen(_storeToken);
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthChange);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleRemoteTap(initialMessage);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final androidGranted = await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final messagingSettings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ??
        messagingSettings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> scheduleReminder(ReminderModel reminder) async {
    final settings = await _settingsFor(reminder.userId);
    if (!settings.pushNotifications || !settings.reminderAlerts) return;
    final scheduledAt = _reminderDateTime(reminder);
    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) return;
    final bodyParts = <String>[
      if (reminder.location.trim().isNotEmpty) reminder.location.trim(),
      if (reminder.category.trim().isNotEmpty) reminder.category.trim(),
    ];
    await _schedule(
      id: reminderNotificationId(reminder.id),
      title: reminder.title,
      body: bodyParts.isEmpty
          ? 'Your maintenance reminder is due.'
          : bodyParts.join(' • '),
      at: _respectQuietHours(scheduledAt, settings),
      sound: settings.sound,
      payload: '/reminders/details|${reminder.id}',
    );
  }

  Future<void> cancelReminder(String reminderId) {
    return _local.cancel(id: reminderNotificationId(reminderId));
  }

  Future<void> scheduleWarranty({
    required String warrantyId,
    required String userId,
    required DateTime expiryDate,
    required String applianceName,
  }) async {
    final settings = await _settingsFor(userId);
    if (!settings.pushNotifications || !settings.dueDateAlerts) return;
    final now = DateTime.now();
    if (!expiryDate.isAfter(now)) return;
    var alertAt = expiryDate.subtract(const Duration(days: 30));
    if (!alertAt.isAfter(now)) alertAt = now.add(const Duration(minutes: 1));
    if (!alertAt.isBefore(expiryDate)) return;
    final deliveryAt = _respectQuietHours(alertAt, settings);
    if (!deliveryAt.isBefore(expiryDate)) return;
    final days = expiryDate.difference(now).inDays;
    final label = applianceName.trim().isEmpty
        ? 'appliance'
        : applianceName.trim();
    await _schedule(
      id: warrantyNotificationId(warrantyId),
      title: 'Warranty Expiring Soon',
      body: 'Your $label warranty expires in ${days.clamp(1, 30)} days.',
      at: deliveryAt,
      sound: settings.sound,
      payload: '/warranties/details|$warrantyId',
    );
  }

  Future<void> cancelWarranty(String warrantyId) {
    return _local.cancel(id: warrantyNotificationId(warrantyId));
  }

  Future<void> applySettings(
    String userId,
    NotificationSettingsModel settings,
  ) async {
    try {
      if (!settings.pushNotifications) {
        await _local.cancelAll();
        return;
      }
      await requestPermission();
      await syncUserSchedules(userId, settings: settings);
    } catch (error) {
      debugPrint('Unable to apply device notification settings: $error');
    }
  }

  Future<void> syncUserSchedules(
    String userId, {
    NotificationSettingsModel? settings,
  }) async {
    final effective = settings ?? await _settingsFor(userId);
    await _local.cancelAll();
    if (!effective.pushNotifications) return;

    if (effective.reminderAlerts) {
      final reminders = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in reminders.docs) {
        final reminder = ReminderModel.fromMap(doc.id, doc.data());
        if (!reminder.isCompleted) await scheduleReminder(reminder);
      }
    }
    if (effective.dueDateAlerts) {
      final warranties = await _firestore
          .collection('warranties')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in warranties.docs) {
        final data = doc.data();
        final expiry = (data['warrantyEndDate'] as Timestamp?)?.toDate();
        if (expiry == null) continue;
        await scheduleWarranty(
          warrantyId: doc.id,
          userId: userId,
          expiryDate: expiry,
          applianceName: _warrantyName(data),
        );
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = _registeredToken ?? await _messaging.getToken();
      if (user != null && token != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
      }
    } catch (error) {
      debugPrint('Unable to unregister FCM token: $error');
    } finally {
      _registeredToken = null;
      await _local.cancelAll();
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) return;
    try {
      await requestPermission();
      final token = await _messaging.getToken();
      if (token != null) await _storeToken(token);
      await syncUserSchedules(user.uid);
    } catch (error) {
      debugPrint('Unable to initialize user notifications: $error');
    }
  }

  Future<void> _storeToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final previousToken = _registeredToken;
    if (previousToken != null && previousToken != token) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayRemove([previousToken]),
      }, SetOptions(merge: true));
    }
    _registeredToken = token;
    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<NotificationSettingsModel> _settingsFor(String userId) async {
    final snapshot = await _firestore
        .collection('notificationSettings')
        .doc(userId)
        .get();
    return NotificationSettingsModel.fromMap(snapshot.data());
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required bool sound,
    required String payload,
  }) async {
    await _local.cancel(id: id);
    await _local.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: sound,
        ),
        iOS: DarwinNotificationDetails(presentSound: sound),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final settings = FirebaseAuth.instance.currentUser == null
        ? const NotificationSettingsModel()
        : await _settingsFor(FirebaseAuth.instance.currentUser!.uid);
    if (!settings.pushNotifications) return;
    await _local.show(
      id:
          (message.messageId?.hashCode ??
              DateTime.now().millisecondsSinceEpoch) &
          0x7fffffff,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: settings.sound,
        ),
      ),
      payload: message.data['route']?.toString() ?? '/notifications',
    );
  }

  void _handleLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    _onOpenRoute?.call(parts.first, parts.length > 1 ? parts[1] : null);
  }

  void _handleRemoteTap(RemoteMessage message) {
    _onOpenRoute?.call(
      message.data['route']?.toString() ?? '/notifications',
      message.data['referenceId'],
    );
  }

  DateTime? _reminderDateTime(ReminderModel reminder) {
    final text = reminder.time?.trim();
    if (text == null || text.isEmpty || text == 'Not set') {
      return DateTime(
        reminder.date.year,
        reminder.date.month,
        reminder.date.day,
        9,
      );
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      hour,
      minute,
    );
  }

  DateTime _respectQuietHours(
    DateTime value,
    NotificationSettingsModel settings,
  ) {
    if (!settings.quietHours) return value;
    final from = _minutes(settings.quietHoursFrom);
    final to = _minutes(settings.quietHoursTo);
    final current = value.hour * 60 + value.minute;
    final isQuiet = from <= to
        ? current >= from && current < to
        : current >= from || current < to;
    if (!isQuiet) return value;
    final toHour = to ~/ 60;
    final toMinute = to % 60;
    final nextDay = from > to && current >= from;
    return DateTime(
      value.year,
      value.month,
      value.day + (nextDay ? 1 : 0),
      toHour,
      toMinute,
    );
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _warrantyName(Map<String, dynamic> data) {
    final brand = data['brand']?.toString().trim() ?? '';
    final type = data['applianceType']?.toString().trim() ?? '';
    return [brand, type].where((part) => part.isNotEmpty).join(' ');
  }

  int reminderNotificationId(String id) => _stableId('reminder:$id');
  int warrantyNotificationId(String id) => _stableId('warranty:$id');

  int _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
