import '../../core/constants/app_constants.dart';
import 'file_type_model.dart';
import 'user_model.dart';

class FileModel {
  final int id;
  final String? fileName;
  final String? originalName;
  final String? path;
  final String? url;
  final String? mimeType;
  final int? size;
  final String? createdAt;
  final String? localPath;
  final int? fileTypeId;
  final FileTypeModel? fileType;
  final UserModel? createdBy;
  final UserModel? updatedBy;

  // Linked entity info
  final int? caseId;
  final String? caseNumber;
  final int? minuteId;
  final String? minuteTitle;
  final int? taskId;
  final String? taskTitle;
  final int? clientId;
  final String? clientName;

  FileModel({
    required this.id,
    this.fileName,
    this.originalName,
    this.path,
    this.url,
    this.mimeType,
    this.size,
    this.createdAt,
    this.localPath,
    this.fileTypeId,
    this.fileType,
    this.createdBy,
    this.updatedBy,
    this.caseId,
    this.caseNumber,
    this.minuteId,
    this.minuteTitle,
    this.taskId,
    this.taskTitle,
    this.clientId,
    this.clientName,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    // Helper to extract first item from a list or return null
    Map<String, dynamic>? _firstOrNull(dynamic list) {
      if (list is List && list.isNotEmpty) {
        final item = list.first;
        if (item is Map) return Map<String, dynamic>.from(item);
      }
      return null;
    }

    // Try to get objects from lists (plural keys) or directly (singular keys)
    final taskObj = _firstOrNull(json['tasks']) ?? (json['task'] is Map ? Map<String, dynamic>.from(json['task']) : null);
    final caseObj = _firstOrNull(json['cases']) ?? (json['case'] is Map ? Map<String, dynamic>.from(json['case']) : null);
    final minuteObj = _firstOrNull(json['minutes']) ?? (json['minute'] is Map ? Map<String, dynamic>.from(json['minute']) : null);
    final clientObj = _firstOrNull(json['clients']) ?? (json['client'] is Map ? Map<String, dynamic>.from(json['client']) : null);

    int? _parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    // Laravel often puts the relationship IDs in the 'pivot' object inside the linked entity
    final pivot = taskObj?['pivot'] ?? caseObj?['pivot'] ?? minuteObj?['pivot'] ?? clientObj?['pivot'];
    final pivotMap = pivot is Map ? pivot : null;

    return FileModel(
      id: _parseId(json['id']) ?? 0,
      fileName: json['file_name'] as String?,
      originalName: json['original_name'] as String? ?? json['file_name'] as String?,
      path: json['file_path'] as String?,
      url: null, // Computed via getter
      mimeType: json['file_type'] as String?,
      size: _parseId(json['file_size']),
      createdAt: json['created_at'] as String?,
      localPath: json['local_path'] as String?,
      fileTypeId: _parseId(json['file_type_id']),
      fileType: json['file_type_relation'] != null && json['file_type_relation'] is Map 
            ? FileTypeModel.fromJson(json['file_type_relation']) 
            : null,
      createdBy: json['created_by'] != null && json['created_by'] is Map 
            ? UserModel.fromJson(json['created_by']) 
            : null,
      updatedBy: json['updated_by'] != null && json['updated_by'] is Map 
            ? UserModel.fromJson(json['updated_by']) 
            : null,
      // Linked entity - try nested objects, then pivot data, then direct id fields
      caseId: _parseId(caseObj?['id']) ?? _parseId(pivotMap?['case_id']) ?? _parseId(json['case_id']),
      caseNumber: caseObj?['case_number'] as String? ?? json['case_number'] as String?,
      minuteId: _parseId(minuteObj?['id']) ?? _parseId(pivotMap?['minute_id']) ?? _parseId(json['minute_id']),
      minuteTitle: minuteObj?['title'] as String? ?? json['minute_title'] as String?,
      taskId: _parseId(taskObj?['id']) ?? _parseId(pivotMap?['task_id']) ?? _parseId(json['task_id']),
      taskTitle: taskObj?['title'] as String? ?? json['task_title'] as String?,
      clientId: _parseId(clientObj?['id']) ?? _parseId(pivotMap?['client_id']) ?? _parseId(json['client_id']),
      clientName: clientObj?['name'] as String? ?? json['client_name'] as String?,
    );
  }





  /// Returns a human-readable description of the linked entity, or null if not linked
  String? get linkedEntityLabel {
    if (caseId != null) {
      return 'قضية: ${caseNumber ?? '#$caseId'}';
    }
    if (minuteId != null) {
      return 'ضبط: ${minuteTitle ?? '#$minuteId'}';
    }
    if (taskId != null) {
      return 'مهمة: ${taskTitle ?? '#$taskId'}';
    }
    if (clientId != null) {
      return 'موكل: ${clientName ?? '#$clientId'}';
    }
    return null;
  }

  String get displayName => originalName ?? fileName ?? 'File $id';

  String? get absoluteUrl {
    if (path == null) return null;
    if (path!.startsWith('http')) return path;

    // Base URL is https://.../api, extract the root domain
    final root = AppConstants.baseUrl.split('/api').first;

    // Laravel 'public' disk files are served via the /storage symlink
    // If path is 'uploads/file.pdf', URL should be 'root/storage/uploads/file.pdf'
    final cleanPath = path!.startsWith('/') ? path : '/$path';
    return '$root/storage$cleanPath';
  }
}

