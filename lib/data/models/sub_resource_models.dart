import 'user_model.dart';

class SessionModel {
  final int id;
  final int caseId;
  final String date;
  final String decisions;
  final String? notes;
  final String? createdAt;
  final String? archivedAt;
  /// من `GET /cases/all-sessions` عند وجود `case_file`
  final String? caseNumber;
  final String? court;
  final String? clientName;
  final UserModel? createdBy;
  final UserModel? updatedBy;

  SessionModel({
    required this.id,
    required this.caseId,
    required this.date,
    required this.decisions,
    this.notes,
    this.createdAt,
    this.archivedAt,
    this.caseNumber,
    this.court,
    this.clientName,
    this.createdBy,
    this.updatedBy,
  });

  bool get isArchived => archivedAt != null && archivedAt!.isNotEmpty;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    var caseId = json['case_file_id'] as int? ?? json['case_id'] as int? ?? 0;
    String? caseNumber;
    String? court;
    String? clientName;

    final cf = json['case_file'];
    if (cf is Map) {
      final cfm = Map<String, dynamic>.from(cf);
      if (cfm['id'] != null) caseId = (cfm['id'] as num).toInt();
      caseNumber = cfm['case_number'] as String?;
      court = cfm['court'] as String?;
      final cl = cfm['client'];
      if (cl is Map) {
        clientName = cl['name'] as String?;
      }
    }

    return SessionModel(
      id: json['id'] as int? ?? 0,
      caseId: caseId,
      date: json['date'] as String? ?? '',
      decisions: json['decisions'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      archivedAt: json['archived_at'] as String?,
      caseNumber: caseNumber,
      court: court,
      clientName: clientName,
      createdBy: json['created_by'] != null && json['created_by'] is Map 
            ? UserModel.fromJson(json['created_by']) 
            : null,
      updatedBy: json['updated_by'] != null && json['updated_by'] is Map 
            ? UserModel.fromJson(json['updated_by']) 
            : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'date': date,
        'decisions': decisions,
        'notes': notes,
        'created_at': createdAt,
        'archived_at': archivedAt,
        'case_number': caseNumber,
        'court': court,
        'client_name': clientName,
      };
}

class CaseNoteModel {
  final int id;
  final int caseId;
  final String date;
  final String content;
  final String? createdAt;

  CaseNoteModel({
    required this.id,
    required this.caseId,
    required this.date,
    required this.content,
    this.createdAt,
  });

  factory CaseNoteModel.fromJson(Map<String, dynamic> json) => CaseNoteModel(
        id: json['id'] as int? ?? 0,
        caseId: json['case_id'] as int? ?? 0,
        date: json['date'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'date': date,
        'content': content,
        'created_at': createdAt,
      };
}

class ExpenseModel {
  final int id;
  final int caseId;
  final String date;
  final String item;
  final double value;
  final String? notes;
  final String? createdAt;

  ExpenseModel({
    required this.id,
    required this.caseId,
    required this.date,
    required this.item,
    required this.value,
    this.notes,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as int? ?? 0,
        caseId: json['case_id'] as int? ?? 0,
        date: json['date'] as String? ?? '',
        item: json['item'] as String? ?? '',
        value: _toDouble(json['value']),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String?,
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'date': date,
        'item': item,
        'value': value,
        'notes': notes,
        'created_at': createdAt,
      };
}

class FeeModel {
  final int id;
  final int caseId;
  final String date;
  final double value;
  final String? notes;
  final String? createdAt;

  FeeModel({
    required this.id,
    required this.caseId,
    required this.date,
    required this.value,
    this.notes,
    this.createdAt,
  });

  factory FeeModel.fromJson(Map<String, dynamic> json) {
    var cid = json['case_id'] as int? ?? json['case_file_id'] as int? ?? 0;
    final cf = json['case_file'];
    if (cf is Map && cf['id'] != null) {
      cid = (cf['id'] as num).toInt();
    }
    return FeeModel(
      id: json['id'] as int? ?? 0,
      caseId: cid,
      date: json['date'] as String? ?? '',
      value: _toDouble(json['value']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'date': date,
        'value': value,
        'notes': notes,
        'created_at': createdAt,
      };
}
