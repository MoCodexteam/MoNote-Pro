// lib/core/utils/notification_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation
            .requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');
      }
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to note
  }

  // Schedule a one-time notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Ensure the scheduled date is in the future
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) {
      debugPrint('Cannot schedule notification in the past: $scheduledDate');
      throw Exception('Scheduled date must be in the future');
    }

    final scheduledTZDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint('Scheduling notification at: $scheduledTZDateTime (local time)');
    
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'note_reminders',
            'Note Reminders',
            channelDescription: 'Notifications for note reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  // Schedule recurring notification (every N days)
  // Note: flutter_local_notifications doesn't support custom intervals like "every 3 days"
  // This will schedule a one-time notification. For recurring, you need to reschedule when notification fires.
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required DateTime startDate,
    required int intervalDays,
    String? payload,
  }) async {
    // Ensure the scheduled date is in the future
    final now = DateTime.now();
    if (startDate.isBefore(now)) {
      debugPrint('Cannot schedule recurring notification in the past: $startDate');
      return;
    }

    // For now, schedule as one-time notification
    // TODO: Implement proper recurring logic by rescheduling on notification tap
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(startDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminders_recurring',
          'Recurring Note Reminders',
          channelDescription: 'Recurring notifications for note reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final notifications = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('Pending notifications count: ${notifications.length}');
    for (var notification in notifications) {
      debugPrint('Pending notification: ID=${notification.id}, Title=${notification.title}');
    }
    return notifications;
  }
}
