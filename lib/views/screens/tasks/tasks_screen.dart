import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/task_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  final bool isNested;
  const TasksScreen({super.key, this.isNested = false});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TaskController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;
      return Scaffold(
      appBar: CustomAppBar(
        title: 'tasks'.tr,
        showBack: !isNested,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterOptions(context, ctrl),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) return const LoadingWidget();
        
        // Only active tasks (not archived)
        final items = ctrl.filteredTasks.where((t) => t.isArchived == false).toList();
        
        if (items.isEmpty) {
          return EmptyStateWidget(
            title: 'no_tasks'.tr,
            icon: Icons.task_outlined,
            onAction:
                canMutate ? () => Get.toNamed(AppRoutes.taskForm) : null,
            actionLabel: 'new_task'.tr,
          );
        }
        
        return RefreshIndicator(
          onRefresh: ctrl.fetchTasks,
          child: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final task = items[i];
              return TaskCard(
                task: task,
                onTap: () => Get.toNamed(AppRoutes.taskDetail,
                    arguments: {'task': task}),
                onComplete: canMutate && task.status != 'completed'
                    ? () => ctrl.completeTask(task.id)
                    : null,
              );
            },
          ),
        );
      }),
      floatingActionButton: canMutate
          ? FloatingActionButton.extended(
              heroTag: 'tasks_fab',
              onPressed: () => Get.toNamed(AppRoutes.taskForm),
              icon: const Icon(Icons.add),
              label: Text('new_task'.tr),
            )
          : null,
    );
    });
  }

  void _showFilterOptions(BuildContext context, TaskController ctrl) {
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
                ...AppConstants.taskStatuses.map(
                  (s) => Obx(() => _FilterChip(
                    label: s.tr,
                    selected: ctrl.filterStatus.value == s,
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const c = AppTheme.primary;
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
