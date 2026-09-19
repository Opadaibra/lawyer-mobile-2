import '../../core/utils/helpers.dart';
import 'user_model.dart';

class TaskModel {
  final int id;
  final int? caseFileId; // case_file_id in API
  final String? caseNumber;
  final String? clientName;
  final String title;
  final String? description;
  final String? taskType;
  final String? nextSessionDate;
  final String? notes;
  final int? fileId;
  final String? dueDate;
  final String status; // pending, in_progress, completed, overdue, suspended
  final bool isArchived;
  final String? createdAt;
  final UserModel? createdBy;
  final UserModel? updatedBy;

  TaskModel({
    required this.id,
    this.caseFileId,
    this.caseNumber,
    this.clientName,
    required this.title,
    this.description,
    this.taskType,
    this.nextSessionDate,
    this.notes,
    this.fileId,
    this.dueDate,
    required this.status,
    this.isArchived = false,
    this.createdAt,
    this.createdBy,
    this.updatedBy,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as int? ?? 0,
        caseFileId: json['case_file_id'] as int?,
        caseNumber: json['case']?['case_number'] as String?,
        clientName: json['case']?['client']?['name'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        taskType: json['task_type'] as String?,
        nextSessionDate: json['next_session_date'] as String?,
        notes: json['notes'] as String?,
        fileId: json['file_id'] as int?,
        dueDate: AppHelpers.normalizeApiDateString(json['due_date']),
        status: json['status'] as String? ?? 'pending',
        isArchived: json['archived_at'] != null,
        createdAt: AppHelpers.normalizeApiDateString(json['created_at']),
        createdBy: json['created_by'] != null && json['created_by'] is Map 
            ? UserModel.fromJson(json['created_by']) 
            : null,
        updatedBy: json['updated_by'] != null && json['updated_by'] is Map 
            ? UserModel.fromJson(json['updated_by']) 
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        if (caseFileId != null) 'case_file_id': caseFileId,
        'title': title,
        'description': description ?? '',
        if (taskType != null) 'task_type': taskType,
        if (nextSessionDate != null) 'next_session_date': nextSessionDate,
        if (notes != null) 'notes': notes,
        if (fileId != null) 'file_id': fileId,
        if (dueDate != null) 'due_date': dueDate,
        'status': status,
      };
}
