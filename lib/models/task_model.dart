enum TaskStatus {
  belumDimulai('Belum Dimulai'),
  sedangDikerjakan('Sedang Dikerjakan'),
  selesai('Selesai');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromLabel(String label) {
    return TaskStatus.values.firstWhere(
      (e) => e.label == label,
      orElse: () => TaskStatus.belumDimulai,
    );
  }
}

enum TaskPriority {
  rendah('Rendah'),
  sedang('Sedang'),
  tinggi('Tinggi');

  final String label;
  const TaskPriority(this.label);

  static TaskPriority fromLabel(String label) {
    return TaskPriority.values.firstWhere(
      (e) => e.label == label,
      orElse: () => TaskPriority.rendah,
    );
  }
}

class TaskModel {
  final int? id;
  final int courseId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final String deadline;
  final String createdAt;

  const TaskModel({
    this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.deadline,
    required this.createdAt,
  });

  TaskModel copyWith({
    int? id,
    int? courseId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    String? deadline,
    String? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'priority': priority.label,
      'status': status.label,
      'deadline': deadline,
      'created_at': createdAt,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      courseId: map['course_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.fromLabel(map['priority'] as String),
      status: TaskStatus.fromLabel(map['status'] as String),
      deadline: map['deadline'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      TaskModel.fromMap(json);

  @override
  String toString() {
    return 'TaskModel(id: $id, courseId: $courseId, title: $title, '
        'description: $description, priority: ${priority.label}, '
        'status: ${status.label}, deadline: $deadline, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel &&
        other.id == id &&
        other.courseId == courseId &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.status == status &&
        other.deadline == deadline &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        courseId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        priority.hashCode ^
        status.hashCode ^
        deadline.hashCode ^
        createdAt.hashCode;
  }
}
