import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (platform might not support): $e');
    }
  }

  /// Send immediate notification (e.g. budget warning)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_alerts',
      'Expense Alerts',
      channelDescription: 'Alerts for budgets, recurring expenses, and logs',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Schedule daily expense tracking reminder (e.g. 8:00 PM)
  Future<void> scheduleDailyReminder({
    int id = 1001,
    int hour = 20,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        'Evening Expense Check-in ✍️',
        "Don't forget to record today's expenses and stay within your budget!",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminders',
            'Daily Reminders',
            channelDescription: 'Daily evening prompts to log expenses',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Trigger budget threshold warning (80% or 100%)
  Future<void> notifyBudgetThreshold({
    required String categoryName,
    required double spent,
    required double limit,
    required double percentage,
  }) async {
    final isExceeded = percentage >= 1.0;
    final title = isExceeded
        ? '⚠️ Budget Exceeded: $categoryName'
        : '⚡ Budget Alert: $categoryName at ${(percentage * 100).toInt()}%';

    final body = isExceeded
        ? 'You have spent \$${spent.toStringAsFixed(2)} exceeding your limit of \$${limit.toStringAsFixed(2)}.'
        : 'You have used ${(percentage * 100).toInt()}% (\$${spent.toStringAsFixed(2)} of \$${limit.toStringAsFixed(2)}).';

    await showNotification(
      id: categoryName.hashCode,
      title: title,
      body: body,
      payload: '/budgets',
    );
  }

  /// Trigger recurring subscription reminder
  Future<void> notifyRecurringRenewal({
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    await showNotification(
      id: title.hashCode,
      title: '📅 Upcoming Subscription Due',
      body: '$title (\$${amount.toStringAsFixed(2)}) is due soon.',
      payload: '/recurring',
    );
  }
}
