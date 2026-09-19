import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/task_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(task.status);
    final isOverdue = AppHelpers.isOverdue(task.dueDate) &&
        task.status != 'completed';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator circle
              GestureDetector(
                onTap: task.status != 'completed' ? onComplete : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                    color: task.status == 'completed'
                        ? statusColor
                        : Colors.transparent,
                  ),
                  child: task.status == 'completed'
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.updatedBy != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('آخر تعديل بواسطة: ${task.updatedBy!.name}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      )
                    else if (task.createdBy != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('تم الإضافة بواسطة: ${task.createdBy!.name}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.status == 'completed'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (task.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_amber
                                : Icons.calendar_today_outlined,
                            size: 12,
                            color: isOverdue
                                ? AppTheme.statusOverdue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppHelpers.formatDateTime(task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? AppTheme.statusOverdue
                                  : Colors.grey,
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    if (task.clientName != null || task.caseNumber != null)
                      Text(
                        '${'task_case_prefix'.tr}: ${task.clientName ?? task.caseNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppHelpers.taskStatusArabic(task.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
