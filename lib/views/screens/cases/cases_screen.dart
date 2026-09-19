import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/case_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CaseController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;
      return Scaffold(
      appBar: CustomAppBar(
        title: 'cases'.tr,
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterOptions(context, ctrl),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const LoadingWidget();
        
        final args = Get.arguments as Map<String, dynamic>?;
        final int? clientId = args?['clientId'];
        
        // Only active cases (not archived)
        var items = ctrl.filteredCases.where((c) => c.isArchived == false).toList();
        
        if (clientId != null) {
          items = items.where((c) => c.clientId == clientId).toList();
        }
        
        if (items.isEmpty) {
          return EmptyStateWidget(
            title: 'no_cases'.tr,
            icon: Icons.folder_outlined,
            onAction:
                canMutate ? () => Get.toNamed(AppRoutes.caseForm) : null,
            actionLabel: 'new_case'.tr,
          );
        }
        
        return RefreshIndicator(
          onRefresh: ctrl.fetchCases,
          child: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final c = items[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Get.toNamed(AppRoutes.caseDetail,
                      arguments: {'case': c}),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.getStatusColor(c.status)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.folder_outlined,
                              color: AppTheme.getStatusColor(c.status)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.updatedBy != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('آخر تعديل بواسطة: ${c.updatedBy!.name}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                )
                              else if (c.createdBy != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('تم الإضافة بواسطة: ${c.createdBy!.name}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              Text(c.caseNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              if (c.clientName != null)
                                Text(c.clientName!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 12)),
                              Text('${c.caseType ?? ''} | ${c.court ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.getStatusColor(c.status)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c.status.tr,
                                style: TextStyle(
                                  color: AppTheme.getStatusColor(c.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (canMutate && c.status != 'closed') ...[
                              GestureDetector(
                                onTap: () => _confirmMarkClosed(ctrl, c.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.5)),
                                  ),
                                  child: const Text(
                                    'فصلت',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (canMutate) ...[
                              const SizedBox(height: 2),
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert,
                                    size: 18, color: Colors.grey),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                          leading: const Icon(Icons.edit_outlined),
                                          title: Text('edit'.tr))),
                                  PopupMenuItem(
                                      value: 'archive',
                                      child: ListTile(
                                          leading: Icon(c.isArchived
                                              ? Icons.unarchive_outlined
                                              : Icons.archive_outlined),
                                          title: Text(c.isArchived
                                              ? 'unarchive'.tr
                                              : 'archive'.tr))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          leading: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          title: Text('delete'.tr,
                                              style: const TextStyle(
                                                  color: Colors.red)))),
                                ],
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    Get.toNamed(AppRoutes.caseForm,
                                        arguments: {'case': c});
                                  } else if (v == 'archive') {
                                    c.isArchived
                                        ? ctrl.unarchiveCase(c.id)
                                        : ctrl.archiveCase(c.id);
                                  } else if (v == 'delete') {
                                    _confirmDelete(ctrl, c.id);
                                  }
                                },
                              ),
                            ],
                          ],
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
      floatingActionButton: canMutate
          ? FloatingActionButton.extended(
              heroTag: 'cases_fab',
              onPressed: () => Get.toNamed(AppRoutes.caseForm),
              icon: const Icon(Icons.add),
              label: Text('new_case'.tr),
            )
          : null,
    );
    });
  }

  void _showFilterOptions(BuildContext context, CaseController ctrl) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('search'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Obx(() => _FilterChip(
                      label: 'all'.tr,
                      selected: ctrl.filterStatus.value.isEmpty,
                      onSelected: () {
                        ctrl.filterStatus.value = '';
                        Get.back();
                      },
                    )),
                ...AppConstants.caseStatuses.map(
                  (s) => Obx(() => _FilterChip(
                        label: s.tr,
                        selected: ctrl.filterStatus.value == s,
                        color: AppTheme.getStatusColor(s),
                        onSelected: () {
                          ctrl.filterStatus.value = s;
                          Get.back();
                        },
                      )),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmMarkClosed(CaseController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('تأكيد - فصلت'),
      content: const Text('هل تريد تحديث حالة هذه الدعوى إلى "فصلت"؟'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.markAsClosed(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('فصلت'),
        ),
      ],
    ));
  }

  void _confirmDelete(CaseController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteCase(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : c,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
