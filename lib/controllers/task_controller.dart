import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/task_model.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/notification_service.dart';
import '../../core/utils/helpers.dart';
import 'auth_controller.dart';
import 'case_controller.dart';
import 'notification_controller.dart';
import 'dashboard_controller.dart';

class TaskController extends GetxController {
  final ApiService _api = ApiService();

  final tasks = <TaskModel>[].obs;
  final archivedTasks = <TaskModel>[].obs;
  final selectedTask = Rx<TaskModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final filterStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.find<AuthController>().isClient) {
      fetchTasks();
    }
  }

  Future<void> fetchTasks() async {
    isLoading.value = true;
    try {
      final response = await _api.getList('${AppConstants.tasks}/');
      final list = _parseList(response);
      tasks.value = list.map((e) => TaskModel.fromJson(e)).toList();
      await NotificationService.checkTaskReminders(tasks);
      _refreshNotificationList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchArchivedTasks() async {
    try {
      final response =
          await _api.getList('${AppConstants.tasks}/?archived=true');
      final list = _parseList(response);
      archivedTasks.value = list.map((e) => TaskModel.fromJson(e)).toList();
    } catch (_) {}
  }

  /// تحديث المهام بدون إظهار مؤشر التحميل (للفحص الدوري).
  Future<void> fetchTasksSilently() async {
    if (Get.find<AuthController>().isClient) return;
    try {
      final response = await _api.getList('${AppConstants.tasks}/');
      final list = _parseList(response);
      tasks.value = list.map((e) => TaskModel.fromJson(e)).toList();
      await NotificationService.checkTaskReminders(tasks);
      _refreshNotificationList();
    } catch (_) {}
  }

  void _refreshNotificationList() {
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().loadNotifications();
    }
  }

  Future<void> fetchTaskById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.tasks}/$id');
      final data = _extractData(response);
      selectedTask.value = TaskModel.fromJson(data);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب مهمة واحدة بدون تعطيل قائمة المهام (مثلاً من الإشعار).
  Future<TaskModel?> fetchTaskByIdQuiet(int id) async {
    try {
      final response = await _api.get('${AppConstants.tasks}/$id');
      final data = _extractData(response);
      return TaskModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  List<TaskModel> get filteredTasks {
    if (filterStatus.value.isEmpty) return tasks;
    return tasks.where((t) => t.status == filterStatus.value).toList();
  }

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == 'pending' && !t.isArchived).toList();

  List<TaskModel> get overdueTasks {
    return tasks.where((t) {
      if (t.dueDate == null || t.isArchived || t.status == 'completed') {
        return false;
      }
      return AppHelpers.isOverdue(t.dueDate);
    }).toList();
  }

  Future<bool> createTask(TaskModel task) async {
    isSubmitting.value = true;
    try {
      final response =
          await _api.post(AppConstants.tasks, data: task.toCreateJson());
      final newTaskId = _parseNewTaskId(response);
      if (newTaskId != null) {
        final recipientId =
            await _resolveClientUserIdForNotification(task.caseFileId);
        if (recipientId != null) {
          try {
            await NotificationService.postNotificationForNewTask(
              taskId: newTaskId,
              recipientUserId: recipientId,
              taskTitle: task.title,
              caseFileId: task.caseFileId,
            );
            _refreshNotificationList();
          } catch (_) {
            // الإشعار اختياري — لا نفشل إنشاء المهمة
          }
        }
      }
      await fetchTasks();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('task_created'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateTask(int id, TaskModel task) async {
    isSubmitting.value = true;
    try {
      await _api.patch('${AppConstants.tasks}/$id', data: task.toCreateJson());
      await fetchTasks();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('task_updated'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> completeTask(int id) async {
    try {
      final task = tasks.firstWhereOrNull((t) => t.id == id);
      if (task == null) return false;
      await _api.patch('${AppConstants.tasks}/$id', data: {
        'case_file_id': task.caseFileId,
        'title': task.title,
        'status': 'completed',
      });
      await fetchTasks();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('task_completed'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _api.delete('${AppConstants.tasks}/$id');
      tasks.removeWhere((t) => t.id == id);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('task_deleted'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> archiveTask(int id) async {
    try {
      await _api.post('${AppConstants.tasks}/$id/archive');
      await fetchTasks();
      await fetchArchivedTasks();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('task_archived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveTask(int id) async {
    try {
      await _api.post('${AppConstants.tasks}/$id/unarchive');
      await fetchTasks();
      await fetchArchivedTasks();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('task_unarchived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['tasks'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  int? _parseNewTaskId(Map<String, dynamic> response) {
    final d = response['data'];
    if (d is Map && d['id'] != null) {
      return (d['id'] as num).toInt();
    }
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map && first['id'] != null) {
        return (first['id'] as num).toInt();
      }
    }
    if (response['id'] != null) {
      return (response['id'] as num).toInt();
    }
    return null;
  }

  Future<int?> _resolveClientUserIdForNotification(int? caseFileId) async {
    if (caseFileId == null) return null;
    if (Get.isRegistered<CaseController>()) {
      final match = Get.find<CaseController>()
          .cases
          .firstWhereOrNull((c) => c.id == caseFileId);
      if (match?.clientUserId != null) return match!.clientUserId;
    }
    try {
      final res = await _api.get('${AppConstants.cases}/$caseFileId');
      final data = _extractData(res);
      final client = data['client'];
      if (client is Map && client['user_id'] != null) {
        return (client['user_id'] as num).toInt();
      }
    } catch (_) {}
    return null;
  }

  void _showError(dynamic e) {
    Get.snackbar(
      'error'.tr,
      e.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccess(String msg) {
    Get.snackbar('success'.tr, msg, snackPosition: SnackPosition.BOTTOM);
  }
}
