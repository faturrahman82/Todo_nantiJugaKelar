import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions manually for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request exact alarms permission for Android 12+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskReminder(
    String id,
    String title,
    DateTime date,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    // 2. Notifikasi H-1 (Persis 24 jam sebelum tenggat di jam pembuatan ini)
    final hMinus1 = DateTime(
      date.year,
      date.month,
      date.day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).subtract(const Duration(days: 1));
    if (hMinus1.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        '$id-hminus1'.hashCode,
        'Pengingat H-1! ⏰',
        'Persiapkan dirimu, tugas "$title" jatuh tempo besok.',
        tz.TZDateTime.from(hMinus1, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 3. Notifikasi Ganti Hari (Jam 00:01 di hari Deadline)
    final midnight = DateTime(date.year, date.month, date.day, 0, 1);
    if (midnight.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        '$id-midnight'.hashCode,
        'Batas Waktu Hari Ini! 🕛',
        'Ingat, hari ini adalah batas akhir untuk tugas "$title".',
        tz.TZDateTime.from(midnight, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 3. Notifikasi Jam 5 Pagi di hari Deadline
    final morning = DateTime(date.year, date.month, date.day, 5, 0);
    if (morning.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        '$id-morning'.hashCode,
        'Peringatan Pagi! 🌅',
        'Ayo semangat, jangan lupa kerjakan tugas "$title" hari ini.',
        tz.TZDateTime.from(morning, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleEventReminder(
    String id,
    String title,
    DateTime eventDate,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'event_reminder_channel',
      'Event Reminders',
      channelDescription: 'Notifications for upcoming events (Mode 2)',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    // Peringatan H-7 (Seminggu Sebelum Acara, jam 9 pagi)
    final hMinus7 = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      9,
      0,
    ).subtract(const Duration(days: 7));

    if (hMinus7.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        '$id-hminus7'.hashCode,
        'Persiapan Seminggu Lagi! ⏳',
        'Sekadar mengingatkan, minggu depan ada: "$title". Sudah disiapkan?',
        tz.TZDateTime.from(hMinus7, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> showImmediateNotification(String id, String title) async {
    const androidDetails = AndroidNotificationDetails(
      'immediate_reminder_channel',
      'Immediate Reminders',
      channelDescription: 'Immediate notifications for newly created tasks',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      '$id-immediate'.hashCode,
      'Alarm Terpasang! 🚨',
      'Tugas "$title" telah dikunci dengan peringatan ke masa depan.',
      notificationDetails,
    );
  }

  Future<void> cancelReminder(String id) async {
    await flutterLocalNotificationsPlugin.cancel('$id-hminus7'.hashCode);
    await flutterLocalNotificationsPlugin.cancel('$id-hminus1'.hashCode);
    await flutterLocalNotificationsPlugin.cancel('$id-midnight'.hashCode);
    await flutterLocalNotificationsPlugin.cancel('$id-morning'.hashCode);
    // Backward compatibility for old scheduled hashes
    await flutterLocalNotificationsPlugin.cancel(id.hashCode);
  }

  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notifikasi Berhasil! 🚀',
      'Ini adalah contoh bagaimana pengingat tugas Anda akan muncul.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminder_channel',
          'Task Reminders',
          channelDescription: 'Notifications for upcoming tasks',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
