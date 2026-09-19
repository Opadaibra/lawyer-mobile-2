import 'dart:async';

import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../data/models/case_model.dart';
import '../data/models/task_model.dart';
import '../data/services/api_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/storage_service.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';
import 'task_controller.dart';

/// فحص دوري (كل 5 دقائق) للمهام وإشعارات التذكير — يعمل مع التطبيق مفتوحاً.
class NotificationPollController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _tick());
    Future<void>.delayed(const Duration(seconds: 15), _tick);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _tick() async {
    if (!StorageService.isLoggedIn()) return;

    final auth = Get.find<AuthController>();
    if (auth.currentUser.value?.isClient == true) {
      await _pollClientPortalTasks();
    } else {
      if (Get.isRegistered<TaskController>()) {
        await Get.find<TaskController>().fetchTasksSilently();
      }
    }

    if (Get.isRegistered<NotificationController>()) {
      await Get.find<NotificationController>()
          .loadNotifications(fromPoll: true);
    }
  }

  Future<void> _pollClientPortalTasks() async {
    try {
      final api = ApiService();
      final response = await api.getList(AppConstants.clientPortal);
      List<dynamic> list = [];
      if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is List) {
        list = response;
      }
      final tasks = <TaskModel>[];
      for (final e in list) {
        final c = CaseModel.fromJson(Map<String, dynamic>.from(e as Map));
        tasks.addAll(c.tasks);
      }
      await NotificationService.checkTaskReminders(tasks);
    } catch (_) {}
  }
}
