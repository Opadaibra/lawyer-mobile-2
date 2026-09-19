import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../data/models/minute_model.dart';
import '../../../data/models/file_model.dart';
import '../../../controllers/minute_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/file_upload_dialog.dart';

class MinuteDetailScreen extends StatelessWidget {
  const MinuteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MinuteModel? minuteData;
    
    if (Get.arguments?['minute'] is MinuteModel) {
      minuteData = Get.arguments['minute'] as MinuteModel;
    }

    if (minuteData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير موجود')),
        body: const Center(child: Text('تفاصيل الضبط غير موجودة')),
      );
    }

    final md = minuteData;

    // Get reactive minute if controller has it (in case of updates)
    return Obx(() {
      final ctrl = Get.find<MinuteController>();
      final auth = Get.find<AuthController>();
      final fileCtrl = Get.find<FileController>();
      final canMutate =
          auth.currentUser.value?.canMutateOfficeContent ?? true;
      final minute =
          ctrl.minutes.firstWhereOrNull((m) => m.id == md.id) ?? md;

      return Scaffold(
        appBar: CustomAppBar(
          title: 'تفاصيل الضبط',
          actions: [
            if (canMutate) ...[
              IconButton(
                icon: Icon(minute.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
                onPressed: () {
                  minute.isArchived ? ctrl.unarchiveMinute(minute.id) : ctrl.archiveMinute(minute.id);
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () => Get.toNamed(AppRoutes.files, arguments: {'minuteId': minute.id}),
            ),
            if (canMutate) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Get.toNamed(AppRoutes.minuteForm, arguments: {'minute': minute}),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(ctrl, minute.id),
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        minute.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            minute.caseNumber ?? 'قضية #${minute.caseFileId}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            AppHelpers.formatDateHuman(
                                minute.date.isNotEmpty ? minute.date : minute.createdAt),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (minute.minuteNumber != null && minute.minuteNumber!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.tag, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('رقم الضبط: ${minute.minuteNumber}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (minute.content != null && minute.content!.isNotEmpty) ...[
                Text(
                  'المحتوى',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      minute.content!,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'معلومات إضافية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (minute.department != null && minute.department!.isNotEmpty)
                        _DetailRow('الدائرة/المحكمة', minute.department!, Icons.account_balance_outlined),
                      if (minute.clientCapacity != null && minute.clientCapacity!.isNotEmpty)
                        _DetailRow('صفة الموكل', minute.clientCapacity!, Icons.person_outline),
                      if (minute.opponent != null && minute.opponent!.isNotEmpty)
                        _DetailRow('الخصم', minute.opponent!, Icons.gavel_outlined),
                      if (minute.opponentCapacity != null && minute.opponentCapacity!.isNotEmpty)
                        _DetailRow('صفة الخصم', minute.opponentCapacity!, Icons.gavel),
                      if (minute.lastProcedure != null && minute.lastProcedure!.isNotEmpty)
                        _DetailRow('آخر إجراء', minute.lastProcedure!, Icons.history),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'المرفقات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (minute.files != null && minute.files!.isNotEmpty) ...[
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: minute.files!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final FileModel f = minute.files![i];
                      return ListTile(
                        leading: const Icon(Icons.attach_file_outlined),
                        title: Text(
                          f.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: f.mimeType != null ? Text(f.mimeType!, style: const TextStyle(fontSize: 11)) : null,
                        onTap: () => Get.toNamed(AppRoutes.fileViewer, arguments: {'file': f}),
                      );
                    },
                  ),
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد مرفقات', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: canMutate ? FloatingActionButton.extended(
          heroTag: 'minute_detail_fab',
          onPressed: () async {
            final result = await Get.dialog<Map<String, String>?>(
              FileUploadDialog(initialType: 'minute', initialId: minute.id),
            );
            if (result != null) {
              final success = await fileCtrl.pickAndUpload(extraFields: result);
              if (success) {
                ctrl.fetchMinuteById(minute.id); // Refresh to show new file
              }
            }
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('رفع مرفق'),
          backgroundColor: AppTheme.accent,
        ) : null,
      );
    });
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
            ctrl.deleteMinute(id).then((success) {
              if (success) {
                Get.back(); // Pop detail screen
              }
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
