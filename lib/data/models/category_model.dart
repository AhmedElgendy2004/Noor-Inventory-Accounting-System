class CategoryModel {
  final String? id;
  final String name;
  final int? color;

  CategoryModel({this.id, required this.name, this.color});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      color: json['color'] != null ? json['color'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (id != null) 'id': id,
      if (color != null) 'color': color,
    };
  }
}
