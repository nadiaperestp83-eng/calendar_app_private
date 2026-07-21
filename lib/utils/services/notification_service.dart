import 'dart:developer';
import 'dart:io';

import 'package:calendar_app/utils/parsing.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  static NotificationService get i => _i;

  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    "eventNotification",
    "Notificações de Eventos",
    channelDescription:
        "Notificações de eventos próximos são enviadas por este canal.",
    importance: Importance.high,
    priority: Priority.high,
    actions: [
      AndroidNotificationAction(
        "ok",
        "OK",
        cancelNotification: true,
      ),
    ],
    category: AndroidNotificationCategory.event,
    autoCancel: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
  );

  static const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  NotificationService._();

  /// Initializes the notification service.
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    if (Platform.isAndroid) {
      final bool? permissionGot = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();

      if (permissionGot != null) _initialized = permissionGot;
    }

    // Initialize the timezone
    tz.initializeTimeZones();

    final bool? initialized = await _flutterLocalNotificationsPlugin
        .initialize(initializationSettings);

    if (initialized == false) _initialized = false;
  }

  Future<bool> scheduleNotification({
    required String eventId,
    required String eventName,
    required DateTime startsAt,
    required int remindAt,
  }) async {
    if (!_initialized) return false;

    final int id = parseNotificationId(eventId);

    final reminderTime = startsAt.subtract(Duration(minutes: remindAt));

    // Se o horário do lembrete já passou (ex: evento criado em cima da
    // hora, ou editado pra um horário próximo demais), não adianta
    // agendar — o plugin lançaria erro ou disparava na hora, o que não
    // é o comportamento esperado de um "lembrete".
    if (reminderTime.isBefore(DateTime.now())) return false;

    final convertedReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        "Seu evento está chegando",
        '"$eventName" começa em $remindAt minutos.',
        convertedReminderTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stackTrace) {
      log(
        "Failed to add notification for event: $eventName ($eventId)",
        name: "NotificationService",
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    }

    return true;
  }

  Future<void> cancelNotification({required String eventId}) async {
    if (!_initialized) return;

    final int id = parseNotificationId(eventId);

    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!_initialized) return [];

    try {
      return await _flutterLocalNotificationsPlugin.getActiveNotifications();
    } on UnimplementedError {
      return [];
    }
  }
}
