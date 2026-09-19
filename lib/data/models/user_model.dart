class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final int? officeId;
  final String? officeName;
  final String? officeAddress;
  final String? officePhone;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.officeId,
    this.officeName,
    this.officeAddress,
    this.officePhone,
    this.createdAt,
  });

  /// هل المستخدم الحالي موكل (CLIENT)؟
  bool get isClient => role?.toUpperCase() == 'CLIENT';

  /// هل المستخدم مدير؟
  bool get isManager => role?.toUpperCase() == 'MANAGER';

  /// وضع الشاهد فقط — عرض بدون إضافة/تعديل/حذف
  bool get isViewerOnly => role?.toUpperCase() == 'VIEWER';

  /// مدير / محامٍ / محرر يمكنهم تعديل بيانات المكتب؛ الشاهد والموكل لا.
  bool get canMutateOfficeContent {
    final r = role?.toUpperCase().trim();
    if (r == 'CLIENT') return false;
    if (r == 'VIEWER') return false;
    // Default to true for Manager, Lawyer, Editor or undefined roles
    return true;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String?,
        officeId: json['office_id'] as int?,
        officeName: json['office']?['name'] as String? ?? json['office_name'] as String?,
        officeAddress: json['office']?['address'] as String? ?? json['office_address'] as String?,
        officePhone: json['office']?['phone'] as String? ?? json['office_phone'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'office_id': officeId,
        'created_at': createdAt,
      };
}
