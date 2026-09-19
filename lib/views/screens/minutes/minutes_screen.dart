import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/minute_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class MinutesScreen extends StatefulWidget {
  const MinutesScreen({super.key});

  @override
  State<MinutesScreen> createState() => _MinutesScreenState();
}

class _MinutesScreenState extends State<MinutesScreen> {
  final ctrl = Get.find<MinuteController>();
  int? caseId;
  int? clientId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    caseId = args?['caseId'];
    clientId = args?['clientId'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (caseId != null) {
        ctrl.fetchMinutesByCase(caseId!);
      } else if (clientId != null) {
        ctrl.fetchMinutesGroupedByClient(clientId!);
      } else {
        ctrl.fetchMinutes();
      }
    });
  }

  Future<void> _refresh() async {
    if (caseId != null) {
      await ctrl.fetchMinutesByCase(caseId!);
    } else if (clientId != null) {
      await ctrl.fetchMinutesGroupedByClient(clientId!);
    } else {
      await ctrl.fetchMinutes();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(
        title: 'minutes'.tr,
        showBack: true,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const LoadingWidget();
        final auth = Get.find<AuthController>();
        final canMutate =
            auth.currentUser.value?.canMutateOfficeContent ?? true;

        // Only active minutes (البيانات القادمة من grouped تكون خاصة بالموكل أصلاً)
        var items = ctrl.minutes.where((m) => m.isArchived == false).toList();
        
        if (items.isEmpty) {
          return EmptyStateWidget(
            title: clientId != null
                ? 'no_minutes_for_client'.tr
                : 'no_minutes'.tr,
            icon: Icons.article_outlined,
            onAction: canMutate
                ? () => Get.toNamed(AppRoutes.minuteForm)
                : null,
            actionLabel: 'add_minute'.tr,
          );
        }
        
        // Group by case
        final Map<String, List<dynamic>> grouped = {};
        for (final m in items) {
          final key = (m.clientName != null && m.clientName!.trim().isNotEmpty)
              ? m.clientName!.trim()
              : (m.caseNumber ?? 'قضية ${m.caseFileId ?? '—'}');
          grouped.putIfAbsent(key, () => []).add(m);
        }
        
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppTheme.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entry.value.length}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((m) => Card(
                        child: ListTile(
                          onTap: () => Get.toNamed(AppRoutes.minuteDetail, arguments: {'minute': m}),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.article_outlined,
                                color: AppTheme.accent),
                          ),
                          title: Text(m.title,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.content != null)
                                Text(m.content!, maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              Text(AppHelpers.formatDateHuman(m.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              if (m.updatedBy != null)
                                Text('آخر تعديل بواسطة: ${m.updatedBy!.name}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11))
                              else if (m.createdBy != null)
                                Text('تم الإضافة بواسطة: ${m.createdBy!.name}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          trailing: canMutate
                              ? PopupMenuButton(
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                            leading: const Icon(Icons.edit_outlined),
                                            title: Text('edit'.tr))),
                                    PopupMenuItem(
                                        value: 'archive',
                                        child: ListTile(
                                            leading: Icon(m.isArchived
                                                ? Icons.unarchive_outlined
                                                : Icons.archive_outlined),
                                            title: Text(m.isArchived
                                                ? 'unarchive'.tr
                                                : 'archive'.tr))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                            leading: const Icon(Icons.delete_outline,
                                                color: Colors.red),
                                            title: Text('delete'.tr,
                                                style: const TextStyle(color: Colors.red)))),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      Get.toNamed(AppRoutes.minuteForm,
                                          arguments: {'minute': m});
                                    } else if (v == 'archive') {
                                      m.isArchived
                                          ? ctrl.unarchiveMinute(m.id)
                                          : ctrl.archiveMinute(m.id);
                                    } else if (v == 'delete') {
                                      _confirmDelete(ctrl, m.id);
                                    }
                                  },
                                )
                              : null,
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final auth = Get.find<AuthController>();
        if (auth.currentUser.value?.canMutateOfficeContent != true) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          heroTag: 'minutes_fab',
          onPressed: () => Get.toNamed(AppRoutes.minuteForm),
          icon: const Icon(Icons.add),
          label: Text('add_minute'.tr),
        );
      }),
    );
  }

  void _confirmDelete(MinuteController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteMinute(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }
}
