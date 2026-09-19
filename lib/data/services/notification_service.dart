import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../app/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../models/case_model.dart';
import '../models/minute_model.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../models/sub_resource_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _zonedTaskBaseId = 500000;

  static bool _isClientUser() {
    final u = StorageService.getUser();
    final r = u?['role']?.toString().toUpperCase();
    return r == 'CLIENT';
  }

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        final p = details.payload;
        if (p != null) {
          _handleLocalNotificationPayload(p).catchError((_) {});
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _handleLocalNotificationPayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final relatedType = data['related_type'] as String?;
      final relatedId = (data['related_id'] as num?)?.toInt();
      final caseFileId = (data['case_file_id'] as num?)?.toInt();

      if (relatedType == 'task' && relatedId != null) {
        if (_isClientUser()) {
          if (caseFileId != null) {
            await _openClientCaseById(caseFileId);
          } else {
            Get.toNamed(AppRoutes.clientPortal);
          }
        } else {
          Get.toNamed(AppRoutes.taskDetail, arguments: {'id': relatedId});
        }
        return;
      }
      if (relatedType == 'case' && relatedId != null) {
        Get.toNamed(AppRoutes.caseDetail, arguments: {'id': relatedId});
        return;
      }
      if (relatedType == 'minute' && relatedId != null && !_isClientUser()) {
        await openMinuteDetailById(relatedId);
        return;
      }
      Get.toNamed(AppRoutes.notifications);
    } catch (_) {}
  }

  static Future<void> _openClientCaseById(int caseId) async {
    try {
      final api = ApiService();
      final response = await api.getList(AppConstants.clientPortal);
      List<dynamic> list = [];
      if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is List) {
        list = response;
      }
      for (final e in list) {
        final c = CaseModel.fromJson(Map<String, dynamic>.from(e as Map));
        if (c.id == caseId) {
          await Get.toNamed(AppRoutes.clientPortalCaseDetail,
              arguments: {'case': c});
          return;
        }
      }
      await Get.toNamed(AppRoutes.clientPortal);
    } catch (_) {
      await Get.toNamed(AppRoutes.clientPortal);
    }
  }

  static Future<void> openMinuteDetailById(int id) async {
    try {
      final api = ApiService();
      final res = await api.get('${AppConstants.minutes}/$id');
      final raw = res['data'] ?? res;
      if (raw is Map) {
        final m = MinuteModel.fromJson(Map<String, dynamic>.from(raw));
        await Get.toNamed(AppRoutes.minuteDetail, arguments: {'minute': m});
      }
    } catch (_) {}
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lawyer_channel',
      'تذكيرات المكتب',
      channelDescription: 'تذكيرات المهام والقضايا',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  static tz.TZDateTime _toTzLocal(DateTime instant) {
    final utcMs = instant.toUtc().millisecondsSinceEpoch;
    return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, utcMs);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final when = _toTzLocal(scheduledDate);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

    final notifId = _zonedTaskBaseId + id;
    await _plugin.cancel(notifId);

    const androidDetails = AndroidNotificationDetails(
      'lawyer_channel',
      'تذكيرات المكتب',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> scheduleDailyReminder(List<TaskModel> tasks, List<SessionModel> sessions) async {
    // Cancel existing scheduled daily reminders to avoid duplicates or stale data
    for (int i = 0; i < 7; i++) {
      try {
        await _plugin.cancel(888 + i);
      } catch (_) {}
    }

    final nowLoc = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 7; i++) {
      final targetDate = DateTime.now().add(Duration(days: i));
      
      var scheduleTime = tz.TZDateTime(
          tz.local, targetDate.year, targetDate.month, targetDate.day, 8, 0);

      // If this scheduled time has already passed (e.g. it is 10:00 AM today and we are calculating for today), skip it
      if (!scheduleTime.isAfter(nowLoc)) {
        continue;
      }

      final tasksToday = tasks.where((t) {
        if (t.dueDate == null || t.status == 'completed') return false;
        final dueUtc = AppHelpers.dueInstantUtc(t.dueDate);
        if (dueUtc == null) return false;
        final dueLocal = dueUtc.toLocal();
        return dueLocal.year == targetDate.year &&
            dueLocal.month == targetDate.month &&
            dueLocal.day == targetDate.day;
      }).length;

      final sessionsToday = sessions.where((s) {
        if (s.date.isEmpty) return false;
        final d = DateTime.tryParse(s.date)?.toLocal();
        if (d == null) return false;
        return d.year == targetDate.year &&
            d.month == targetDate.month &&
            d.day == targetDate.day;
      }).length;

      if (tasksToday == 0 && sessionsToday == 0) continue;

      String body = '';
      if (tasksToday > 0 && sessionsToday > 0) {
        body = 'لديك $tasksToday مهمة و $sessionsToday جلسة مجدولة لهذا اليوم.';
      } else if (tasksToday > 0) {
        body = 'لديك $tasksToday مهمة مجدولة لهذا اليوم.';
      } else {
        body = 'لديك $sessionsToday جلسة مجدولة لهذا اليوم.';
      }

      await _plugin.zonedSchedule(
        888 + i,
        'تذكير الصباح',
        body,
        scheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'تذكير يومي',
            channelDescription: 'ملخص المواعيد كل صباح',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// تذكيرات الجدولة المحلية فقط (بدون تخزين في قائمة الإشعارات — القائمة من السيرفر).
  static Future<void> checkTaskReminders(List<TaskModel> tasks) async {
    final nowUtc = DateTime.now().toUtc();

    for (final task in tasks) {
      if (task.dueDate == null || task.isArchived || task.status == 'completed') {
        continue;
      }
      final dueUtc = AppHelpers.dueInstantUtc(task.dueDate);
      if (dueUtc == null) continue;

      if (dueUtc.isAfter(nowUtc)) {
        await scheduleNotification(
          id: task.id,
          title: 'حان وقت المهمة',
          body: '«${task.title}»',
          scheduledDate: DateTime.fromMillisecondsSinceEpoch(
            dueUtc.millisecondsSinceEpoch,
            isUtc: true,
          ),
          payload: jsonEncode({
            'related_type': 'task',
            'related_id': task.id,
            'case_file_id': task.caseFileId,
          }),
        );
      }
    }
  }

  static Future<void> checkSessionReminders(List<SessionModel> sessions) async {
    final nowUtc = DateTime.now().toUtc();

    for (final session in sessions) {
      if (session.date.isEmpty) continue;
      final sessionUtc = AppHelpers.dueInstantUtc(session.date);
      if (sessionUtc == null) continue;

      if (sessionUtc.isAfter(nowUtc)) {
        await scheduleNotification(
          id: 1000000 + session.id, // Use a different base to avoid collision with tasks
          title: 'موعد جلسة قادمة',
          body: 'جلسة لقضية رقم: ${session.caseNumber ?? "غير معروف"}',
          scheduledDate: sessionUtc,
          payload: jsonEncode({
            'related_type': 'case',
            'related_id': session.caseId,
          }),
        );
      }
    }
  }

  // ─── API إشعارات التطبيق ─────────────────────────────────────────────────

  static Future<List<NotificationModel>> fetchNotificationsFromApi() async {
    if (!StorageService.isLoggedIn()) return [];
    final api = ApiService();
    final path = _isClientUser()
        ? AppConstants.clientPortalNotifications
        : AppConstants.notifications;
    final res = await api.get(path);
    final data = res['data'];
    if (data is! List) return [];
    final list = data
        .map((e) =>
            NotificationModel.fromApiJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> markNotificationReadApi(int id) async {
    final api = ApiService();
    final base = _isClientUser()
        ? AppConstants.clientPortalNotifications
        : AppConstants.notifications;
    await api.patch('$base/$id/read', data: {});
  }

  /// إشعار بمهمة جديدة للمستخدم المستهدف (عادة حساب الموكل) مع `task_id`.
  static Future<void> postNotificationForNewTask({
    required int taskId,
    required int recipientUserId,
    required String taskTitle,
    int? caseFileId,
  }) async {
    if (!StorageService.isLoggedIn()) return;
    final api = ApiService();
    await api.post(AppConstants.notifications, data: {
      'user_id': recipientUserId,
      'title': 'إشعار بمهمة جديدة',
      'message': 'تم إسناد مهمة جديدة لقضيتك: «$taskTitle»',
      'task_id': taskId,
      if (caseFileId != null) 'case_file_id': caseFileId,
    });
  }

  /// إظهار دفع محلي لإشعار جديد من السيرفر (معرّف فريد لتفادي التصادم).
  static int pushIdForServerNotification(int serverId) =>
      1 + (serverId % 2000000000);

  static String payloadForServerNotification(NotificationModel n) {
    return jsonEncode({
      'related_type': n.relatedType,
      'related_id': n.relatedId,
      'case_file_id': n.caseFileId,
    });
  }
}
