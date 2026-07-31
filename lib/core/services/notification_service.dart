import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/schedule/domain/models/schedule_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialize Timezones (required for zonedSchedule)
    tz.initializeTimeZones();
    // Default fallback to UTC or a generic local timezone location
    tz.setLocalLocation(tz.getLocation('UTC'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap here if needed
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _initialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  // Generates notification ID from schedule UUID hash
  int _getNotificationId(String uuid) {
    return uuid.hashCode & 0x7FFFFFFF; // Ensure positive 32-bit integer
  }

  Future<void> scheduleScheduleReminder(ScheduleModel schedule) async {
    if (!_initialized) await init();

    final parts = schedule.startTime.split(':');
    if (parts.length < 2) return;

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduleTime = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
      hour,
      minute,
    );

    // Reminder time is 10 minutes before the start time
    final reminderTime = scheduleTime.subtract(const Duration(minutes: 10));

    // If reminder time has already passed, skip scheduling
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Skipping reminder schedule for "${schedule.title}" because the reminder time has already passed.');
      return;
    }

    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'schedule_reminders_channel',
      'Schedule Reminders',
      channelDescription: 'Notifications for upcoming daily schedules',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = _getNotificationId(schedule.id);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Upcoming Schedule: ${schedule.title}',
        'Your schedule starts in 10 minutes at ${schedule.startTime}',
        tzReminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: schedule.id,
      );
      debugPrint('Scheduled notification for "${schedule.title}" at $reminderTime (ID: $id)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelScheduleReminder(String scheduleId) async {
    if (!_initialized) await init();
    final id = _getNotificationId(scheduleId);
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('Cancelled notification for schedule ID: $scheduleId (ID: $id)');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
