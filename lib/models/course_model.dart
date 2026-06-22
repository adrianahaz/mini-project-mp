class CourseModel {
  final int? id;
  final String name;

  const CourseModel({this.id, required this.name});

  CourseModel copyWith({int? id, String? name}) {
    return CourseModel(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{if (id != null) 'id': id, 'name': name};
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(id: map['id'] as int?, name: map['name'] as String);
  }

  Map<String, dynamic> toJson() => toMap();

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      CourseModel.fromMap(json);

  @override
  String toString() => 'CourseModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
