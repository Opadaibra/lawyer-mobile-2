import '../../core/utils/helpers.dart';

/// إشعار من الـ API (جدول app_notifications).
int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final int? taskId;
  final int? minuteId;
  final int? caseFileId;
  /// دائماً بتوقيت UTC (لحظة فعلية من السيرفر).
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.taskId,
    this.minuteId,
    this.caseFileId,
    required this.createdAt,
  });

  int? get relatedId => taskId ?? minuteId ?? caseFileId;

  String? get relatedType {
    if (taskId != null) return 'task';
    if (minuteId != null) return 'minute';
    if (caseFileId != null) return 'case';
    return null;
  }

  /// لتلوين الأيقونة والعرض.
  String get type {
    if (taskId != null) return 'task_reminder';
    if (minuteId != null) return 'minute';
    if (caseFileId != null) return 'case_reminder';
    return 'general';
  }

  factory NotificationModel.fromApiJson(Map<String, dynamic> json) {
    final readRaw = json['is_read'];
    var read = false;
    if (readRaw is bool) {
      read = readRaw;
    } else if (readRaw is int) {
      read = readRaw != 0;
    }

    final titleRaw = json['title'] as String?;
    final title = (titleRaw != null && titleRaw.trim().isNotEmpty)
        ? titleRaw.trim()
        : 'إشعار';

    final rawId = json['id'];
    final id = rawId is int ? rawId : (rawId as num).toInt();

    var taskId = _intOrNull(json['task_id']);
    if (taskId == null && json['task'] is Map) {
      taskId = _intOrNull((json['task'] as Map)['id']);
    }
    var minuteId = _intOrNull(json['minute_id']);
    if (minuteId == null && json['minute'] is Map) {
      minuteId = _intOrNull((json['minute'] as Map)['id']);
    }
    var caseFileId = _intOrNull(json['case_file_id']);
    if (caseFileId == null && json['case_file'] is Map) {
      caseFileId = _intOrNull((json['case_file'] as Map)['id']);
    }

    return NotificationModel(
      id: id,
      title: title,
      message: (json['message'] as String?) ?? '',
      isRead: read,
      taskId: taskId,
      minuteId: minuteId,
      caseFileId: caseFileId,
      createdAt: AppHelpers.parseApiDateTimeUtc(json['created_at']),
    );
  }
}
