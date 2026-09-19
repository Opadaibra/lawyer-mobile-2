import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/task_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/file_model.dart';
import '../../../data/services/api_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TaskController>();
    final auth = Get.find<AuthController>();
    final args = Get.arguments as Map<String, dynamic>?;

    TaskModel? fromArgs;
    int? idArg;
    if (args?['task'] is TaskModel) {
      fromArgs = args!['task'] as TaskModel;
    } else if (args?['id'] != null) {
      idArg = args!['id'] is int
          ? args['id'] as int
          : int.tryParse(args['id'].toString());
      if (idArg != null) {
        fromArgs = ctrl.tasks.firstWhereOrNull((t) => t.id == idArg);
      }
    }

    final resolved = fromArgs;
    if (resolved != null) {
      return _TaskDetailView(task: resolved, ctrl: ctrl, auth: auth);
    }

    if (idArg != null && !auth.isClient) {
      return FutureBuilder<TaskModel?>(
        future: ctrl.fetchTaskByIdQuiet(idArg),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Scaffold(
              appBar: CustomAppBar(title: 'task_detail'.tr),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final t = snap.data;
          if (t == null) {
            return Scaffold(
              appBar: AppBar(title: Text('task_not_found'.tr)),
              body: Center(child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('task_not_found_body'.tr, textAlign: TextAlign.center),
              )),
            );
          }
          return _TaskDetailView(task: t, ctrl: ctrl, auth: auth);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('task_not_found'.tr)),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('task_not_found_body'.tr, textAlign: TextAlign.center),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TaskDetailView extends StatelessWidget {
  final TaskModel task;
  final TaskController ctrl;
  final AuthController auth;

  const _TaskDetailView({
    required this.task,
    required this.ctrl,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(task.status);
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'task_detail'.tr,
        actions: [
          if (canMutate)
            PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text('edit'.tr))),
                PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                        leading: Icon(task.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined),
                        title: Text(
                            task.isArchived ? 'unarchive'.tr : 'archive_verb'.tr))),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('delete'.tr,
                            style: const TextStyle(color: Colors.red)))),
              ],
              onSelected: (v) {
                if (v == 'edit') {
                  Get.toNamed(AppRoutes.taskForm, arguments: {'task': task});
                } else if (v == 'archive') {
                  task.isArchived
                      ? ctrl.unarchiveTask(task.id)
                      : ctrl.archiveTask(task.id);
                } else {
                  _confirmDelete(context, ctrl, task.id);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.task_outlined, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: statusColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppHelpers.taskStatusArabic(task.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Detail Tiles ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailTile(Icons.calendar_today_outlined,
                        'task_due_date'.tr, AppHelpers.formatDateTime(task.dueDate)),
                    if (task.caseNumber != null)
                      _DetailTile(Icons.folder_outlined, 'task_case'.tr,
                          task.caseNumber!),
                    _DetailTile(Icons.access_time_outlined, 'task_created_at'.tr,
                        AppHelpers.formatDateHuman(task.createdAt)),
                    if (task.isArchived)
                      _DetailTile(Icons.archive_outlined,
                          'task_archived_label'.tr, 'yes'.tr),
                  ],
                ),
              ),
            ),

            // ── Description ───────────────────────────────────────────
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('task_description'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(task.description!,
                          style: const TextStyle(height: 1.6)),
                    ],
                  ),
                ),
              ),
            ],

            // ── File Attachments ──────────────────────────────────────
            const SizedBox(height: 16),
            _TaskFilesSection(task: task, canMutate: canMutate),

            // ── Complete Button ───────────────────────────────────────
            const SizedBox(height: 24),
            if (task.status != 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ctrl.completeTask(task.id).then((_) => Get.back()),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('mark_task_complete'.tr),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete_task_title'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Get.back();
            ctrl.deleteTask(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }
}

// ── Task Files Section ────────────────────────────────────────────────────────
class _TaskFilesSection extends StatefulWidget {
  final TaskModel task;
  final bool canMutate;
  const _TaskFilesSection({required this.task, required this.canMutate});

  @override
  State<_TaskFilesSection> createState() => _TaskFilesSectionState();
}

class _TaskFilesSectionState extends State<_TaskFilesSection> {
  final fileCtrl = Get.find<FileController>();
  final _taskFiles = <FileModel>[].obs;
  final _loaded = false.obs;

  @override
  void initState() {
    super.initState();
    _loadTaskFiles();
  }

  Future<void> _loadTaskFiles() async {
    try {
      final api = ApiService();
      final response = await api.getList('/files/by-task/${widget.task.id}');
      
      List<dynamic> list = [];
      if (response is List) {
        list = response;
      } else if (response is Map) {
        list = response['data'] as List? ?? response['files'] as List? ?? [];
      }
      
      debugPrint('Loaded ${list.length} files for task ${widget.task.id}');
      _taskFiles.value = list.map((e) {
        try {
          return FileModel.fromJson(Map<String, dynamic>.from(e));
        } catch (err) {
          debugPrint('Error parsing file item: $err');
          return null;
        }
      }).whereType<FileModel>().toList();
    } catch (e) {
      debugPrint('Error loading task files: $e');
    } finally {
      _loaded.value = true;
    }
  }


  Map<String, String> get _taskFields => {'task_id': widget.task.id.toString()};

  void _showUploadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('upload_file'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _UploadOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'الكاميرا',
                  color: AppTheme.primary,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUploadFromCamera(extraFields: _taskFields);
                    if (success) _loadTaskFiles();
                  },
                ),
                _UploadOption(
                  icon: Icons.photo_library_outlined,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUploadFromGallery(extraFields: _taskFields);
                    if (success) _loadTaskFiles();
                  },
                ),
                _UploadOption(
                  icon: Icons.attach_file_outlined,
                  label: 'ملف',
                  color: Colors.orange,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUpload(extraFields: _taskFields);
                    if (success) _loadTaskFiles();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('الملفات المرفقة',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (widget.canMutate)
                  Obx(() => fileCtrl.isUploading.value
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.primary),
                          tooltip: 'upload_file'.tr,
                          onPressed: _showUploadOptions,
                        )),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // File list
            Obx(() {
              if (!_loaded.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              
              if (_taskFiles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'لا توجد ملفات مرفقة بعد',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _taskFiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final f = _taskFiles[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openFile(context, f),
                    leading: Icon(
                      AppHelpers.getFileIcon(f.displayName),
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      f.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: f.size != null
                        ? Text(AppHelpers.formatFileSize(f.size!),
                            style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: widget.canMutate
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            onPressed: () async {
                              final del = await fileCtrl.deleteFile(f.id);
                              if (del) _taskFiles.removeWhere((x) => x.id == f.id);
                            },
                          )
                        : null,
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}


// ── Upload Option Widget ──────────────────────────────────────────────────────
class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Detail Tile ───────────────────────────────────────────────────────────────
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

void _openFile(BuildContext context, FileModel file) async {
  if (file.absoluteUrl != null) {
    Get.toNamed('/file-viewer', arguments: {'file': file});
    return;
  }
  if (file.localPath != null && File(file.localPath!).existsSync()) {
    await OpenFilex.open(file.localPath!);
    return;
  }
  Get.snackbar('خطأ', 'لا يوجد رابط أو مسار محلي للملف');
}
