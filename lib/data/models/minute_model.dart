import 'file_model.dart';
import 'user_model.dart';

String? _minuteClientName(Map<String, dynamic> json) {
  final top = json['client'];
  if (top is Map && top['name'] != null) {
    return top['name'].toString();
  }
  final caseObj = json['case'];
  if (caseObj is Map) {
    final cl = caseObj['client'];
    if (cl is Map && cl['name'] != null) {
      return cl['name'].toString();
    }
    if (caseObj['client_name'] != null) {
      return caseObj['client_name'].toString();
    }
  }
  return null;
}

class MinuteModel {
  final int id;
  final int? caseFileId;
  final int? clientId;
  final String? clientName;
  final String? caseNumber;
  final String title;
  final String date;
  final String? minuteNumber;
  final String? department;
  final String? clientCapacity;
  final String? opponent;
  final String? opponentCapacity;
  final String? lastProcedure;
  final String? content;
  final int? fileId;
  final bool isArchived;
  final bool isStarred;
  final String? createdAt;
  final UserModel? createdBy;
  final UserModel? updatedBy;
  /// مرفقات مدمجة مع المحضر (مثلاً من `GET /minutes/client/{id}/grouped`)
  final List<FileModel>? files;

  MinuteModel({
    required this.id,
    this.caseFileId,
    this.clientId,
    this.clientName,
    this.caseNumber,
    required this.title,
    required this.date,
    this.minuteNumber,
    this.department,
    this.clientCapacity,
    this.opponent,
    this.opponentCapacity,
    this.lastProcedure,
    this.content,
    this.fileId,
    this.isArchived = false,
    this.isStarred = false,
    this.createdAt,
    this.createdBy,
    this.updatedBy,
    this.files,
  });

  factory MinuteModel.fromJson(Map<String, dynamic> json) => MinuteModel(
        id: json['id'] as int? ?? 0,
        caseFileId: json['case_file_id'] as int?,
        clientId: json['client_id'] as int?,
        clientName: _minuteClientName(json),
        caseNumber: json['case']?['case_number'] as String?,
        title: json['title'] as String? ?? json['number'] as String? ?? json['minute_number'] as String? ?? 'Minute',
        date: json['date'] as String? ?? '',
        minuteNumber: json['number'] as String? ?? json['minute_number'] as String?,
        department: json['court_department'] as String? ?? json['department'] as String?,
        clientCapacity: json['client_status'] as String? ?? json['client_capacity'] as String?,
        opponent: json['opponent'] as String?,
        opponentCapacity: json['opponent_status'] as String? ?? json['opponent_capacity'] as String?,
        lastProcedure: json['last_procedure'] as String?,
        content: json['content'] as String? ?? json['notes'] as String?,
        fileId: json['file_id'] as int?,
        isArchived: json['archived_at'] != null,
        isStarred: json['is_starred'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? (json['created_at'].toString().endsWith('Z')
                ? json['created_at']
                : '${json['created_at']}Z')
            : null,
        createdBy: json['created_by'] != null && json['created_by'] is Map 
            ? UserModel.fromJson(json['created_by']) 
            : null,
        updatedBy: json['updated_by'] != null && json['updated_by'] is Map 
            ? UserModel.fromJson(json['updated_by']) 
            : null,
        files: json['files'] is List
            ? (json['files'] as List)
                .whereType<Map>()
                .map((e) => FileModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        if (caseFileId != null) 'case_file_id': caseFileId,
        if (clientId != null) 'client_id': clientId,
        'title': title,
        'date': date,
        if (minuteNumber != null) 'number': minuteNumber,
        if (department != null) 'court_department': department,
        if (clientCapacity != null) 'client_status': clientCapacity,
        if (opponent != null) 'opponent': opponent,
        if (opponentCapacity != null) 'opponent_status': opponentCapacity,
        if (lastProcedure != null) 'last_procedure': lastProcedure,
        'content': content ?? '',
        if (fileId != null) 'file_id': fileId,
      };

  Map<String, dynamic> toUpdateJson() => {
        ...toCreateJson(),
        'is_starred': isStarred,
      };
}
