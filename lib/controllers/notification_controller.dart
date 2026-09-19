import 'package:get/get.dart';

import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';

class NotificationController extends GetxController {
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  bool _hadFirstFetch = false;

  void resetForLogout() {
    notifications.clear();
    unreadCount.value = 0;
    _hadFirstFetch = false;
  }

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// [fromPoll]: عند true نعرض إشعاراً محلياً للعناصر الجديدة غير المقروءة.
  Future<void> loadNotifications({bool fromPoll = false}) async {
    isLoading.value = true;
    try {
      final previousIds = notifications.map((n) => n.id).toSet();
      final list = await NotificationService.fetchNotificationsFromApi();

      if (_hadFirstFetch && fromPoll) {
        for (final n in list) {
          if (!previousIds.contains(n.id) && !n.isRead) {
            await NotificationService.showNotification(
              id: NotificationService.pushIdForServerNotification(n.id),
              title: n.title,
              body: n.message,
              payload: NotificationService.payloadForServerNotification(n),
            );
          }
        }
      }
      _hadFirstFetch = true;

      notifications.assignAll(list);
      unreadCount.value = list.where((n) => !n.isRead).length;
    } catch (e) {
      if (notifications.isEmpty) {
        Get.snackbar(
          'error'.tr,
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationService.markNotificationReadApi(id);
      await loadNotifications();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    try {
      for (final n in unread) {
        await NotificationService.markNotificationReadApi(n.id);
      }
      await loadNotifications();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
