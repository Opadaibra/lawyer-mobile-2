class ClientModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String? powerOfAttorneyNumber;
  final bool isStarred;
  final String? profilePicture;
  final String? createdAt;
  // حقل مؤقت فقط عند الإنشاء - لا يحفظ من السيرفر
  final String? password;

  ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.powerOfAttorneyNumber,
    this.isStarred = false,
    this.profilePicture,
    this.createdAt,
    this.password,
  });

  String? get profilePictureUrl {
    if (profilePicture == null || profilePicture!.isEmpty) return null;
    if (profilePicture!.startsWith('http')) return profilePicture;
    return 'http://127.0.0.1:8000/storage/$profilePicture';
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        notes: json['notes'] as String?,
        powerOfAttorneyNumber: json['power_of_attorney_number'] as String?,
        isStarred: json['is_starred'] as bool? ?? false,
        profilePicture: json['image'] as String? ?? json['profile_picture'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'power_of_attorney_number': powerOfAttorneyNumber,
        'is_starred': isStarred,
        'image': profilePicture,
        'created_at': createdAt,
      };

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        if (powerOfAttorneyNumber != null)
          'power_of_attorney_number': powerOfAttorneyNumber,
        if (password != null && password!.isNotEmpty) 'password': password,
      };
}
