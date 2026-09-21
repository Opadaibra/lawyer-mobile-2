import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/file_upload_dialog.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final fileCtrl = Get.find<FileController>();
  int? caseId;
  int? minuteId;
  int? taskId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    caseId = args?['caseId'];
    minuteId = args?['minuteId'];
    taskId = args?['taskId'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  Future<void> _loadFiles() async {
    if (caseId != null) {
      await fileCtrl.fetchFilesByCase(caseId!);
    } else if (minuteId != null) {
      await fileCtrl.fetchFilesByMinute(minuteId!);
    } else if (taskId != null) {
      await fileCtrl.fetchFilesByTask(taskId!);
    } else {
      await fileCtrl.fetchFiles();
    }
  }

  Future<void> _refresh() => _loadFiles();

  Map<String, String> get _extraFields {
    final fields = <String, String>{};
    if (caseId != null) fields['case_id'] = caseId.toString();
    if (minuteId != null) fields['minute_id'] = minuteId.toString();
    if (taskId != null) fields['task_id'] = taskId.toString();
    return fields;
  }

  bool get _isScoped => caseId != null || minuteId != null || taskId != null;

  bool get _allowMultiUpload => caseId != null;

  void _showUploadOptions(BuildContext context, bool canMutate) async {
    if (!canMutate) return;

    Map<String, String> fields = _extraFields;

    String? initType;
    int? initId;
    bool fixed = false;
    
    if (caseId != null) {
      initType = 'case';
      initId = caseId;
      fixed = true;
    } else if (minuteId != null) {
      initType = 'minute';
      initId = minuteId;
      fixed = true;
    } else if (taskId != null) {
      initType = 'task';
      initId = taskId;
      fixed = true;
    }

    final selectedFields = await Get.dialog<Map<String, String>?>(
      FileUploadDialog(initialType: initType, initialId: initId, isFixed: fixed),
    );
    
    if (selectedFields == null) return; // User cancelled
    
    // Add extraFields that might not be returned if fixed (like case_id)
    fields.addAll(selectedFields);

    // Now show source options
    if (!mounted) return;
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
            Text(_allowMultiUpload ? 'اختيار مصدر الملفات' : 'اختيار مصدر الملف',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _UploadOptionTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'الكاميرا',
                  color: AppTheme.primary,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUploadFromCamera(extraFields: fields);
                    if (success) _loadFiles();
                  },
                ),
                _UploadOptionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUploadFromGallery(
                      extraFields: fields,
                      allowMultiple: _allowMultiUpload,
                    );
                    if (success) _loadFiles();
                  },
                ),
                _UploadOptionTile(
                  icon: Icons.attach_file_outlined,
                  label: _allowMultiUpload ? 'ملفات' : 'ملف',
                  color: Colors.orange,
                  onTap: () async {
                    Get.back();
                    final success = await fileCtrl.pickAndUpload(
                      extraFields: fields,
                      allowMultiple: _allowMultiUpload,
                    );
                    if (success) _loadFiles();
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
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: caseId != null
            ? 'ملفات القضية'
            : minuteId != null
                ? 'ملفات المحضر'
                : taskId != null
                    ? 'ملفات المهمة'
                    : 'الملفات',
        showBack: _isScoped,
      ),
      body: Obx(() {
        if (fileCtrl.isLoading.value) return const LoadingWidget();
        final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

        if (fileCtrl.files.isEmpty) {
          return EmptyStateWidget(
            title: 'لم يتم رفع ملفات',
            icon: Icons.folder_open_outlined,
            onAction: canMutate
                ? () => _showUploadOptions(context, canMutate)
                : null,
            actionLabel: _allowMultiUpload ? 'رفع ملفات' : 'رفع ملف',
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: fileCtrl.files.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (_, i) {
              final file = fileCtrl.files[i];
              final linkedLabel = file.linkedEntityLabel;
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppTheme.primary.withOpacity(0.1),
                      child: _buildFileLeading(file),
                    ),
                  ),
                  title: Text(
                    file.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (file.size != null)
                        Text(AppHelpers.formatFileSize(file.size!),
                            style: const TextStyle(fontSize: 11)),
                      Text(AppHelpers.formatDateHuman(file.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      // ── Linked entity label ──────────────────────
                      if (linkedLabel != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_linkedIcon(file),
                                  size: 12, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                linkedLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (file.fileType != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'نوع الملف: ${file.fileType!.name}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (file.updatedBy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('آخر تعديل بواسطة: ${file.updatedBy!.name}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        )
                      else if (file.createdBy != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('تم الإضافة بواسطة: ${file.createdBy!.name}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new_outlined,
                            color: AppTheme.primary),
                        onPressed: () => _openFile(context, file),
                        tooltip: 'عرض',
                      ),
                      if (canMutate)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                          onPressed: () => _editFileType(context, file),
                          tooltip: 'تعديل التصنيف',
                        ),
                      if (canMutate)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _confirmDelete(fileCtrl, file.id),
                          tooltip: 'حذف',
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final canMutate =
            auth.currentUser.value?.canMutateOfficeContent ?? true;
        if (!canMutate) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: fileCtrl.isUploading.value
              ? null
              : () => _showUploadOptions(context, canMutate),
          icon: fileCtrl.isUploading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.upload_file_outlined),
          label: Text(fileCtrl.isUploading.value
              ? 'جاري الرفع'
              : (_allowMultiUpload ? 'رفع ملفات' : 'رفع ملف')),
        );
      }),
    );
  }

  IconData _linkedIcon(dynamic file) {
    if (file.caseId != null) return Icons.folder_outlined;
    if (file.minuteId != null) return Icons.description_outlined;
    if (file.taskId != null) return Icons.task_outlined;
    if (file.clientId != null) return Icons.person_outlined;
    return Icons.link;
  }

  void _openFile(BuildContext context, dynamic file) async {
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

  Widget _buildFileLeading(dynamic file) {
    if (_isImage(file.displayName)) {
      if (file.absoluteUrl != null) {
        return Image.network(
          file.absoluteUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            AppHelpers.getFileIcon(file.displayName),
            color: AppTheme.primary,
          ),
        );
      } else if (file.localPath != null &&
          File(file.localPath!).existsSync()) {
        return Image.file(
          File(file.localPath!),
          fit: BoxFit.cover,
        );
      }
    }
    return Icon(
      AppHelpers.getFileIcon(file.displayName),
      color: AppTheme.primary,
    );
  }

  bool _isImage(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  void _editFileType(BuildContext context, dynamic file) {
    int? selectedFileTypeId = file.fileTypeId;
    
    Get.dialog(AlertDialog(
      title: const Text('تعديل تصنيف الملف'),
      content: GetX<FileController>(
        init: Get.find<FileController>(),
        builder: (fCtrl) {
          return DropdownButtonFormField<int>(
            value: selectedFileTypeId,
            decoration: const InputDecoration(
              labelText: 'نوع الملف',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('بدون تصنيف')),
              ...fCtrl.fileTypes.map((ft) => DropdownMenuItem(
                value: ft.id,
                child: Text(ft.name),
              )),
            ],
            onChanged: (v) {
              selectedFileTypeId = v;
            },
          );
        },
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            fileCtrl.updateFileType(file.id, selectedFileTypeId);
          },
          child: const Text('حفظ'),
        ),
      ],
    ));
  }

  void _confirmDelete(FileController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('حذف الملف'),
      content: const Text('هل أنت متأكد؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteFile(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}

// ── Upload Option Tile ────────────────────────────────────────────────────────
class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UploadOptionTile({
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
