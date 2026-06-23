import 'package:equatable/equatable.dart';

import '../models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum ada aksi apapun.
class TaskInitial extends TaskState {
  const TaskInitial();
}

/// State saat data sedang dimuat atau operasi CRUD sedang berjalan.
class TaskLoading extends TaskState {
  const TaskLoading();
}

/// State saat data berhasil dimuat dari database.
/// [tasks]           : daftar task yang ditampilkan.
/// [activeCourseId]  : id course yang sedang difilter; null berarti semua course.
class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final int? activeCourseId;

  const TaskLoaded({required this.tasks, this.activeCourseId});

  @override
  List<Object?> get props => [tasks, activeCourseId];
}

/// State saat terjadi error pada operasi apapun.
class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
