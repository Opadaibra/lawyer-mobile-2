import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/client_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../data/models/task_model.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/notification_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/config/app_config.dart';
import '../../data/services/storage_service.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  final isLoading = false.obs;
  final totalClients = 0.obs;
  final totalCases = 0.obs;
  final pendingTasks = 0.obs;
  final overdueTasks = 0.obs;
  final totalSessions = 0.obs;
  final recentClients = <ClientModel>[].obs;
  final recentCases = <dynamic>[].obs;
  final recentMinutes = <dynamic>[].obs;
  final allTasks = <TaskModel>[].obs;
  /// جلسات من `GET /cases/all-sessions`
  final allSessions = <SessionModel>[].obs;

  List<SessionModel> get pastSessions {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return allSessions.where((session) {
      if (session.isArchived) return false;
      if (session.date.isEmpty) return false;
      final d = DateTime.tryParse(session.date)?.toLocal();
      if (d == null) return false;
      final sessionDay = DateTime(d.year, d.month, d.day);
      return sessionDay.isBefore(today);
    }).toList();
  }

  final focusedDay = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    if (AppConfig.requireOnlineLogin && StorageService.getToken() != 'offline') {
      _verifyUserActive();
    }
    loadDashboard();
  }

  Future<void> _verifyUserActive() async {
    try {
      await _api.getList('/cases?limit=1');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized') || msg.contains('unauthenticated') || msg.contains('انتهت صلاحية')) {
         Get.find<AuthController>().logout();
      }
    }
  }

  Future<void> refreshDashboard() => loadDashboard();

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  List<dynamic> filterItemsByDate(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final tasks = allTasks.where((task) {
      if (task.dueDate == null) return false;
      final dueUtc = AppHelpers.dueInstantUtc(task.dueDate);
      if (dueUtc == null) return false;
      final d = dueUtc.toLocal();
      
      // إخفاء المهام القديمة التي تاريخها أقدم من اليوم في التقويم
      final taskDay = DateTime(d.year, d.month, d.day);
      if (taskDay.isBefore(today)) return false;

      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();

    final sessions = allSessions.where((session) {
      if (session.isArchived) return false;
      if (session.date.isEmpty) return false;
      final d = DateTime.tryParse(session.date)?.toLocal();
      if (d == null) return false;

      // إخفاء الجلسات القديمة التي تاريخها أقدم من اليوم في التقويم
      final sessionDay = DateTime(d.year, d.month, d.day);
      if (sessionDay.isBefore(today)) return false;

      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();

    return [...tasks, ...sessions];
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadClients(),
        _loadCases(),
        _loadTasks(),
        _loadMinutes(),
        _loadAllSessions(),
      ]);
      NotificationService.scheduleDailyReminder(allTasks, allSessions);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadClients() async {
    try {
      final response = await _api.getList('/clients/');
      final list = _parseList(response);
      totalClients.value = list.length;
      final clients = list.map((e) => ClientModel.fromJson(e)).toList();
      recentClients.value = clients.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadCases() async {
    try {
      final response = await _api.getList('/cases/');
      final list = _parseList(response);
      totalCases.value = list.length;
      recentCases.value = list.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadAllSessions() async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/all-sessions');
      final list = _parseList(response);
      final sessions = list
          .map((e) =>
              SessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((s) => !s.isArchived)
          .toList();
      sessions.sort((a, b) {
        try {
          return a.date.compareTo(b.date);
        } catch (_) {
          return 0;
        }
      });
      allSessions.assignAll(sessions);
      totalSessions.value = sessions.length;
      NotificationService.checkSessionReminders(sessions);
    } catch (_) {
      allSessions.clear();
      totalSessions.value = 0;
    }
  }

  Future<void> _loadMinutes() async {
    try {
      final response = await _api.getList('/minutes/');
      final list = _parseList(response);
      recentMinutes.value = list.take(5).toList();
    } catch (_) {}
  }

  Future<void> _loadTasks() async {
    try {
      final response = await _api.getList('/tasks/');
      final list = _parseList(response);
      final tasks = list.map((e) => TaskModel.fromJson(e)).toList();
      allTasks.value = tasks;
      // نعد المهام النشطة (غير المكتملة)
      pendingTasks.value =
          tasks.where((t) => t.status != 'completed' && !t.isArchived).length;
      overdueTasks.value = tasks.where((t) {
        if (t.dueDate == null || t.status == 'completed' || t.isArchived) return false;
        return AppHelpers.isOverdue(t.dueDate);
      }).length;
    } catch (_) {}
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) return response['data'] as List? ?? [];
    return [];
  }

  /// تحديث قائمة الجلسات فقط (مثلاً من شاشة «كل الجلسات»).
  Future<void> reloadAllSessions() => _loadAllSessions();
}
