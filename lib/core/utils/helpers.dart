import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  static const List<String> _monthsAr = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  /// Format date to readable string
  static String formatDate(String? dateStr, {String pattern = 'yyyy-MM-dd'}) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat(pattern).format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date to human readable (Arabic Months)
  static String formatDateHuman(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final normalized = normalizeApiDateString(dateStr) ?? dateStr;
      final date = DateTime.parse(normalized).toLocal();
      final monthName = _monthsAr[date.month - 1];
      return '${date.day} $monthName ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date-time (Arabic Months)
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final normalized = normalizeApiDateString(dateStr) ?? dateStr;
      final date = DateTime.parse(normalized).toLocal();
      final monthName = _monthsAr[date.month - 1];
      final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '${date.day} $monthName ${date.year} – $time';
    } catch (_) {
      return dateStr;
    }
  }

  static String formatTimeOnly(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final normalized = normalizeApiDateString(dateStr) ?? dateStr;
      final date = DateTime.parse(normalized).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(11, 16) : dateStr;
    }
  }

  /// تحليل تاريخ السيرفر كـ UTC (يتجنب فرق التوقيت عند غياب Z في النص).
  static DateTime parseApiDateTimeUtc(dynamic raw) {
    final n = normalizeApiDateString(raw);
    if (n == null || n.isEmpty) return DateTime.now().toUtc();
    try {
      return DateTime.parse(n).toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }

  /// عرض لحظة UTC بتوقيت الجهاز المحلي.
  static String formatDateTimeLocalFromUtc(DateTime utcInstant) {
    final date = utcInstant.toLocal();
    final time = DateFormat('HH:mm').format(date);
    return '${date.day} ${_monthsAr[date.month - 1]} ${date.year} – $time';
  }

  /// تطبيع سلسلة التاريخ القادمة من الـ API لمقارنة دقيقة (UTC).
  static String? normalizeApiDateString(dynamic raw) {
    if (raw == null) return null;
    var s = raw.toString().trim();
    if (s.isEmpty) return null;
    
    // إذا كان يحتوي على مسافة بدلاً من T، نحولها لـ T لتسهيل التحليل
    if (s.contains(' ') && !s.contains('T')) {
      s = s.replaceFirst(' ', 'T');
    }

    if (s.endsWith('Z')) return s;
    if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s)) return s;
    
    // إذا لم يكن هناك منطقة زمنية، نفترض أنه UTC القادم من السيرفر
    return '${s}Z';
  }

  /// لحظة الاستحقاق كـ UTC (للمقارنة مع DateTime.now().toUtc()).
  static DateTime? dueInstantUtc(String? dateStr) {
    final n = normalizeApiDateString(dateStr);
    if (n == null) return null;
    try {
      return DateTime.parse(n).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Check if a date is overdue
  static bool isOverdue(String? dateStr) {
    final due = dueInstantUtc(dateStr);
    if (due == null) return false;
    return due.isBefore(DateTime.now().toUtc());
  }

  /// Days until a date
  static int daysUntil(String? dateStr) {
    final due = dueInstantUtc(dateStr);
    if (due == null) return 0;
    return due.difference(DateTime.now().toUtc()).inDays;
  }

  /// حالة المهمة للعرض (عربي فقط)
  static String taskStatusArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'معلقة';
      case 'in_progress':
        return 'جارية';
      case 'completed':
        return 'فصلت';
      case 'overdue':
        return 'متأخرة';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  /// Status display label
  static String statusLabel(String status, BuildContext context) {
    // Bilingual status
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open / مفتوحة';
      case 'closed':
        return 'Closed / فصلت';
      case 'pending':
        return 'Pending / قائمة';
      case 'archived':
        return 'Archived / مؤرشفة';
      case 'in_progress':
        return 'In Progress / جارية';
      case 'completed':
        return 'Completed / فصلت';
      case 'overdue':
        return 'Overdue / متأخرة';
      default:
        return status;
    }
  }

  /// Get file icon by extension
  static IconData getFileIcon(String? filename) {
    if (filename == null) return Icons.insert_drive_file;
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Format file size
  static String formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
