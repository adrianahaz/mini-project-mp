import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/course_model.dart';
import '../services/database_service.dart';
import 'course_state.dart';

class CourseCubit extends Cubit<CourseState> {
  final DatabaseService _db;

  CourseCubit({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService.instance,
      super(const CourseInitial());

  // ---------------------------------
  // LOAD
  // ---------------------------------

  /// Memuat seluruh course dari database.
  /// Dipanggil saat halaman pertama kali dibuka,
  /// dan secara otomatis setelah setiap operasi CRUD berhasil.
  Future<void> loadCourses() async {
    emit(const CourseLoading());
    try {
      final courses = await _db.getAllCourses();
      if (isClosed) return;
      emit(CourseLoaded(courses));
    } catch (e) {
      if (isClosed) return;
      emit(CourseError('Gagal memuat data courses: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // ADD
  // ---------------------------------

  /// Menambahkan course baru ke database.
  /// Setelah berhasil, secara otomatis memanggil [loadCourses]
  /// agar UI selalu menampilkan data terbaru.
  Future<void> addCourse(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      emit(const CourseError('Nama course tidak boleh kosong.'));
      return;
    }

    emit(const CourseLoading());
    try {
      final course = CourseModel(name: trimmed);
      await _db.insertCourse(course);
      await loadCourses();
    } catch (e) {
      if (isClosed) return;
      emit(CourseError('Gagal menambahkan course: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // UPDATE
  // ---------------------------------

  /// Memperbarui data course yang sudah ada.
  /// [course] harus memiliki id yang valid (tidak null).
  /// Setelah berhasil, secara otomatis memanggil [loadCourses].
  Future<void> updateCourse(CourseModel course) async {
    if (course.id == null) {
      emit(const CourseError('Course tidak valid: id tidak ditemukan.'));
      return;
    }

    final trimmedName = course.name.trim();
    if (trimmedName.isEmpty) {
      emit(const CourseError('Nama course tidak boleh kosong.'));
      return;
    }

    emit(const CourseLoading());
    try {
      await _db.updateCourse(course.copyWith(name: trimmedName));
      await loadCourses();
    } catch (e) {
      if (isClosed) return;
      emit(CourseError('Gagal memperbarui course: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // DELETE
  // ---------------------------------

  /// Menghapus course berdasarkan [id].
  /// Seluruh tasks yang berelasi akan ikut terhapus (ON DELETE CASCADE).
  /// Setelah berhasil, secara otomatis memanggil [loadCourses].
  Future<void> deleteCourse(int id) async {
    emit(const CourseLoading());
    try {
      await _db.deleteCourse(id);
      await loadCourses();
    } catch (e) {
      if (isClosed) return;
      emit(CourseError('Gagal menghapus course: ${e.toString()}'));
    }
  }
}
