class CategoryModel {
  final String? id;
  final String name;

  CategoryModel({this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, if (id != null) 'id': id};
  }
}
