import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/case_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../controllers/notification_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ClientPortalScreen extends StatefulWidget {
  const ClientPortalScreen({super.key});

  @override
  State<ClientPortalScreen> createState() => _ClientPortalScreenState();
}

class _ClientPortalScreenState extends State<ClientPortalScreen> {
  final ApiService _api = ApiService();
  final isLoading = true.obs;
  final cases = <CaseModel>[].obs;

  @override
  void initState() {
    super.initState();
    _fetchMyCases();
  }

  Future<void> _fetchMyCases() async {
    try {
      isLoading.value = true;
      final response = await _api.getList(AppConstants.clientPortal);
      if (response is Map && response['data'] is List) {
        cases.value = (response['data'] as List)
            .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (response is List) {
        cases.value = response
            .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final tasks = <TaskModel>[];
      for (final c in cases) {
        tasks.addAll(c.tasks);
      }
      await NotificationService.checkTaskReminders(tasks);
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().loadNotifications();
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header خاص بالموكل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'م',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مرحباً، ${auth.userName}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const Text('بوابة الموكل - قضاياي',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Obx(() {
                    final notifCtrl = Get.find<NotificationController>();
                    final count = notifCtrl.unreadCount.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          tooltip: 'notifications'.tr,
                          onPressed: () =>
                              Get.toNamed(AppRoutes.notifications),
                        ),
                        if (count > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () {
                      Get.dialog(AlertDialog(
                        title: Text('logout'.tr),
                        content: const Text('سيتم تسجيل الخروج. انتبه: أي بيانات لم يتم مزامنتها مسبقاً قد يتم فقدانها.'),
                        actions: [
                          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              auth.logout();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text('logout'.tr),
                          ),
                        ],
                      ));
                    },
                  ),
                ],
              ),
            ),

            // قائمة القضايا
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (cases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 72, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('لا توجد قضايا مرتبطة بحسابك',
                            style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('تواصل مع محاميك لمزيد من المعلومات',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _fetchMyCases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cases.length,
                    itemBuilder: (ctx, i) => _buildCaseCard(context, cases[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseModel c) {
    final statusColor = _statusColor(c.status);
    final sessionCount = c.sessions.length;
    final minuteCount = c.minutes.length;
    final fileCount = c.linkedFiles.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.clientPortalCaseDetail,
            arguments: {'case': c}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.caseNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (c.caseType != null && c.caseType!.isNotEmpty)
                      Text(
                        c.caseType!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(c.status),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        _chip(Icons.event_outlined, '$sessionCount جلسة'),
                        _chip(Icons.article_outlined, '$minuteCount ضبط'),
                        _chip(Icons.attach_file, '$fileCount مرفق'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض التفاصيل الكاملة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_left,
                            size: 18, color: AppTheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.statusOpen;
      case 'closed':
        return AppTheme.statusClosed;
      case 'pending':
        return AppTheme.statusPending;
      case 'archived':
        return AppTheme.statusArchived;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      case 'pending':
        return 'معلقة';
      case 'archived':
        return 'مؤرشفة';
      default:
        return status;
    }
  }
}
