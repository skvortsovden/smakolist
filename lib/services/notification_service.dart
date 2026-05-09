import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _tzChannel = MethodChannel('com.texapp.smakolist/timezone');

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'smakolist_reminders';
  static const _breakfastId = 1;
  static const _lunchId = 2;
  static const _dinnerId = 3;

  bool _initialized = false;
  Completer<void>? _readyCompleter;

  Future<void> init() async {
    if (_readyCompleter != null) return;
    final completer = Completer<void>();
    _readyCompleter = completer;
    try {
      await _doInit().timeout(const Duration(seconds: 10));
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: init failed or timed out ($e).');
    } finally {
      completer.complete();
    }
  }

  Future<void> _doInit() async {
    tz.initializeTimeZones();
    try {
      final tzName =
          await _tzChannel.invokeMethod<String>('getLocalTimezone') ?? 'UTC';
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('NotificationService: timezone init failed ($e), using UTC.');
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> _awaitReady() async {
    if (_readyCompleter == null) return false;
    await _readyCompleter!.future;
    return _initialized;
  }

  Future<bool> requestPermission() async {
    if (!await _awaitReady()) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  Future<bool> isPermissionGranted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required bool enabled,
  }) async {
    if (!enabled) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
      return;
    }
    if (!await _awaitReady()) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Нагадування про їжу',
        channelDescription: 'Нагадування додати запис до Смаколиста',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      debugPrint(
          'NotificationService: exact alarm unavailable ($e), falling back to inexact.');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> scheduleBreakfast(TimeOfDay time, {required bool enabled}) =>
      scheduleReminder(
        id: _breakfastId,
        title: 'Смаколист — Сніданок',
        body: 'Час записати, що ти снідаєш!',
        time: time,
        enabled: enabled,
      );

  Future<void> scheduleLunch(TimeOfDay time, {required bool enabled}) =>
      scheduleReminder(
        id: _lunchId,
        title: 'Смаколист — Обід',
        body: 'Час записати, що ти обідаєш!',
        time: time,
        enabled: enabled,
      );

  Future<void> scheduleDinner(TimeOfDay time, {required bool enabled}) =>
      scheduleReminder(
        id: _dinnerId,
        title: 'Смаколист — Вечеря',
        body: 'Час записати, що ти вечеряєш!',
        time: time,
        enabled: enabled,
      );
}
