import 'package:equatable/equatable.dart';

import '../models/course_model.dart';

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum ada aksi apapun.
class CourseInitial extends CourseState {
  const CourseInitial();
}

/// State saat data sedang dimuat atau operasi CRUD sedang berjalan.
class CourseLoading extends CourseState {
  const CourseLoading();
}

// State saat data berhasil dimuat dari database.
class CourseLoaded extends CourseState {
  final List<CourseModel> courses;

  const CourseLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

/// State saat terjadi error pada operasi apapun.
class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}
