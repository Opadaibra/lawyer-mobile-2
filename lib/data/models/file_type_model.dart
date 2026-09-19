class FileTypeModel {
  final int id;
  final String name;

  FileTypeModel({
    required this.id,
    required this.name,
  });

  factory FileTypeModel.fromJson(Map<String, dynamic> json) => FileTypeModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
