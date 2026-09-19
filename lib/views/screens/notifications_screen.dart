import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/case_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/notification_service.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static Future<void> _openClientCase(int caseId) async {
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
      Get.snackbar('error'.tr, 'case_not_found'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('error'.tr,
          e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  static Future<void> _onNotificationTap(
    NotificationController ctrl,
    AuthController auth,
    NotificationModel notif,
  ) async {
    await ctrl.markAsRead(notif.id);

    if (notif.relatedType == 'task' && notif.relatedId != null) {
      if (auth.isClient) {
        if (notif.caseFileId != null) {
          await _openClientCase(notif.caseFileId!);
        } else {
          Get.toNamed(AppRoutes.clientPortal);
        }
      } else {
        Get.toNamed(AppRoutes.taskDetail,
            arguments: {'id': notif.relatedId});
      }
      return;
    }

    if (notif.relatedType == 'minute' && notif.relatedId != null) {
      if (!auth.isClient) {
        await NotificationService.openMinuteDetailById(notif.relatedId!);
      }
      return;
    }

    if (notif.relatedType == 'case') {
      final caseId = notif.caseFileId ?? notif.relatedId;
      if (caseId != null) {
        if (auth.isClient) {
          await _openClientCase(caseId);
        } else {
          Get.toNamed(AppRoutes.caseDetail, arguments: {'id': caseId});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'notifications_screen_title'.tr,
        showNotification: false,
        actions: [
          TextButton(
            onPressed: () async {
              await ctrl.markAllAsRead();
            },
            child: Text('mark_all_read'.tr,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = ctrl.notifications;
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ctrl.loadNotifications(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: EmptyStateWidget(
                    title: 'no_notifications'.tr,
                    icon: Icons.notifications_off_outlined,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ctrl.loadNotifications(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final notif = items[i];
              return Card(
                key: ValueKey(notif.id),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: notif.isRead
                    ? null
                    : AppTheme.primary.withOpacity(0.05),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onNotificationTap(ctrl, auth, notif),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getNotifColor(notif.type)
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotifIcon(notif.type),
                            color: _getNotifColor(notif.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif.message,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppHelpers.formatDateTimeLocalFromUtc(
                                    notif.createdAt),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'overdue':
        return AppTheme.error;
      case 'task_reminder':
        return AppTheme.warning;
      case 'case_reminder':
        return AppTheme.info;
      case 'minute':
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'overdue':
        return Icons.warning_amber_outlined;
      case 'task_reminder':
        return Icons.task_outlined;
      case 'case_reminder':
        return Icons.folder_outlined;
      case 'minute':
        return Icons.article_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
