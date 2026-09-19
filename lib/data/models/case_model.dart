import 'sub_resource_models.dart';
import 'file_model.dart';
import 'minute_model.dart';
import 'task_model.dart';
import 'user_model.dart';

int? _intFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class CaseModel {
  final int id;
  final int? clientId;
  /// معرّف مستخدم حساب الموكل (للإشعارات) إن وُجد في استجابة الـ API
  final int? clientUserId;
  final String? clientName;
  final String caseNumber;
  final String? caseType;
  final String? court;
  final String? subject;
  final String? department;
  final String? clientCapacity;
  final String? opponent;
  final String? opponentCapacity;
  final double totalFeesPaid;
  /// من `GET /cases/{id}/fees` عند كون `data` كائناً (total_fees / total_paid)
  final double? feesApiAgreedTotal;
  final double? feesApiPaidTotal;
  final String? nextSessionDate;
  final String? notes;
  final String status;
  final bool isArchived;
  final bool isStarred;
  final int? fileId;
  final String? createdAt;
  final String? updatedAt;
  final UserModel? createdBy;
  final UserModel? updatedBy;

  // Sub-resources
  final List<SessionModel> sessions;
  final List<CaseNoteModel> caseNotes;
  final List<ExpenseModel> expenses;
  final List<FeeModel> fees;
  /// مرفقات القضية (مثل استجابة بوابة الموكل)
  final List<FileModel> linkedFiles;
  final List<MinuteModel> minutes;
  final List<TaskModel> tasks;

  CaseModel({
    required this.id,
    this.clientId,
    this.clientUserId,
    this.clientName,
    required this.caseNumber,
    this.caseType,
    this.court,
    this.subject,
    this.department,
    this.clientCapacity,
    this.opponent,
    this.opponentCapacity,
    this.totalFeesPaid = 0.0,
    this.feesApiAgreedTotal,
    this.feesApiPaidTotal,
    this.nextSessionDate,
    this.notes,
    required this.status,
    this.isArchived = false,
    this.isStarred = false,
    this.fileId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.sessions = const [],
    this.caseNotes = const [],
    this.expenses = const [],
    this.fees = const [],
    this.linkedFiles = const [],
    this.minutes = const [],
    this.tasks = const [],
  });

  static double _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: json['id'] as int? ?? 0,
        clientId: json['client_id'] as int?,
        clientUserId: () {
          final c = json['client'];
          if (c is Map) {
            return _intFromJson(c['user_id']);
          }
          return _intFromJson(json['client_user_id']);
        }(),
        clientName: json['client']?['name'] as String? ?? json['client_name'] as String?,
        caseNumber: json['case_number'] as String? ?? '',
        caseType: json['case_type'] as String?,
        court: json['court'] as String?,
        subject: json['subject'] as String?,
        department: json['court_department'] as String? ?? json['department'] as String?,
        clientCapacity: json['client_status'] as String? ?? json['client_capacity'] as String?,
        opponent: json['opponent'] as String?,
        opponentCapacity: json['opponent_status'] as String? ?? json['opponent_capacity'] as String?,
        totalFeesPaid: _parseMoney(json['total_fees_paid'] ?? json['total_fees_payments']),
        nextSessionDate: json['next_session_date'] as String?,
        notes: json['notes'] as String?,
        status: json['status'] as String? ?? 'open',
        isArchived: json['archived_at'] != null,
        isStarred: json['is_starred'] as bool? ?? false,
        fileId: json['file_id'] as int?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        createdBy: json['created_by'] != null && json['created_by'] is Map 
            ? UserModel.fromJson(json['created_by']) 
            : null,
        updatedBy: json['updated_by'] != null && json['updated_by'] is Map 
            ? UserModel.fromJson(json['updated_by']) 
            : null,
        sessions: (json['sessions'] as List?)
                ?.map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        caseNotes: (json['notes_records'] as List?)
                ?.map((e) => CaseNoteModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        expenses: (json['expenses'] as List?)
                ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        fees: (json['fees'] as List?)
                ?.map((e) => FeeModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        linkedFiles: (json['files'] as List?)
                ?.map((e) => FileModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        minutes: (json['minutes'] as List?)?.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              m['case'] ??= {
                'case_number': json['case_number'],
                'court': json['court'],
                'case_type': json['case_type'],
              };
              return MinuteModel.fromJson(m);
            }).toList() ??
            [],
        tasks: (json['tasks'] as List?)?.map((e) {
              final t = Map<String, dynamic>.from(e as Map);
              t['case'] ??= {'case_number': json['case_number']};
              return TaskModel.fromJson(t);
            }).toList() ??
            [],
      );

  Map<String, dynamic> toCreateJson() => {
        'client_id': clientId,
        'case_number': caseNumber,
        if (caseType != null) 'case_type': caseType,
        if (court != null) 'court': court,
        if (subject != null) 'subject': subject,
        if (department != null) 'court_department': department,
        if (clientCapacity != null) 'client_status': clientCapacity,
        if (opponent != null) 'opponent': opponent,
        if (opponentCapacity != null) 'opponent_status': opponentCapacity,
        if (nextSessionDate != null) 'next_session_date': nextSessionDate,
        if (notes != null) 'notes': notes,
        if (fileId != null) 'file_id': fileId,
        'status': status,
      };

  Map<String, dynamic> toUpdateJson() => {
        ...toCreateJson(),
        'is_starred': isStarred,
      };

  CaseModel copyWith({
    int? id,
    int? clientId,
    int? clientUserId,
    String? clientName,
    String? caseNumber,
    String? caseType,
    String? court,
    String? subject,
    String? department,
    String? clientCapacity,
    String? opponent,
    String? opponentCapacity,
    double? totalFeesPaid,
    double? feesApiAgreedTotal,
    double? feesApiPaidTotal,
    String? nextSessionDate,
    String? notes,
    String? status,
    bool? isArchived,
    bool? isStarred,
    int? fileId,
    List<SessionModel>? sessions,
    List<CaseNoteModel>? caseNotes,
    List<ExpenseModel>? expenses,
    List<FeeModel>? fees,
    List<FileModel>? linkedFiles,
    List<MinuteModel>? minutes,
    List<TaskModel>? tasks,
  }) {
    return CaseModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientUserId: clientUserId ?? this.clientUserId,
      clientName: clientName ?? this.clientName,
      caseNumber: caseNumber ?? this.caseNumber,
      caseType: caseType ?? this.caseType,
      court: court ?? this.court,
      subject: subject ?? this.subject,
      department: department ?? this.department,
      clientCapacity: clientCapacity ?? this.clientCapacity,
      opponent: opponent ?? this.opponent,
      opponentCapacity: opponentCapacity ?? this.opponentCapacity,
      totalFeesPaid: totalFeesPaid ?? this.totalFeesPaid,
      feesApiAgreedTotal: feesApiAgreedTotal ?? this.feesApiAgreedTotal,
      feesApiPaidTotal: feesApiPaidTotal ?? this.feesApiPaidTotal,
      nextSessionDate: nextSessionDate ?? this.nextSessionDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      isStarred: isStarred ?? this.isStarred,
      fileId: fileId ?? this.fileId,
      sessions: sessions ?? this.sessions,
      caseNotes: caseNotes ?? this.caseNotes,
      expenses: expenses ?? this.expenses,
      fees: fees ?? this.fees,
      linkedFiles: linkedFiles ?? this.linkedFiles,
      minutes: minutes ?? this.minutes,
      tasks: tasks ?? this.tasks,
    );
  }
}
