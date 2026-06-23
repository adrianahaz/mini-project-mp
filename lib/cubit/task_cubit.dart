import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task_model.dart';
import '../services/database_service.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final DatabaseService _db;

  /// Menyimpan courseId terakhir yang digunakan oleh [loadTasksByCourse].
  /// Dipakai oleh [_refresh] untuk menentukan scope reload setelah CRUD.
  int? _activeCourseId;

  TaskCubit({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService.instance,
      super(const TaskInitial());

  // ---------------------------------
  // INTERNAL REFRESH
  // ---------------------------------

  /// Memuat ulang data sesuai konteks aktif.
  /// - Jika [_activeCourseId] tersedia -> reload per course.
  /// - Jika tidak -> reload semua tasks.
  Future<void> _refresh() async {
    if (_activeCourseId != null) {
      await loadTasksByCourse(_activeCourseId!);
    } else {
      await loadTasks();
    }
  }

  // ---------------------------------
  // LOAD - SEMUA TASKS
  // ---------------------------------

  /// Memuat seluruh tasks dari semua course, diurutkan by deadline.
  /// Mereset [_activeCourseId] ke null (tidak ada filter aktif).
  Future<void> loadTasks() async {
    _activeCourseId = null;
    emit(const TaskLoading());
    try {
      final tasks = await _db.getAllTasks();
      emit(TaskLoaded(tasks: tasks));
    } catch (e) {
      emit(TaskError('Gagal memuat data tasks: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // LOAD - TASKS BY COURSE
  // ---------------------------------

  /// Memuat tasks yang berelasi dengan [courseId].
  /// Menyimpan [courseId] ke [_activeCourseId] agar refresh otomatis.
  /// setelah CRUD tetap berada dalam scope course yang sama.
  Future<void> loadTasksByCourse(int courseId) async {
    _activeCourseId = courseId;
    emit(const TaskLoading());
    try {
      final tasks = await _db.getTasksByCourse(courseId);
      emit(TaskLoaded(tasks: tasks, activeCourseId: courseId));
    } catch (e) {
      emit(TaskError('Gagal memuat tasks untuk course ini: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // ADD
  // ---------------------------------

  /// Menambahkan task baru ke database.
  /// Setelah berhasil, melakukan refresh otomatis sesuai scope aktif.
  Future<void> addTask(TaskModel task) async {
    final validationError = _validateTask(task);
    if (validationError != null) {
      emit(TaskError(validationError));
      return;
    }

    emit(const TaskLoading());
    try {
      await _db.insertTask(task);
      await _refresh();
    } catch (e) {
      emit(TaskError('Gagal menambahkan task: ${e.toString()}'));
    }
  }

  // ---------------------------------
  // UPDATE
  // ---------------------------------

  /// Memperbarui seluruh data task.
  /// [task] harus memiliki id yang valid (tidak null).
  /// Setelah berhasil, melakukan refresh otomatis sesuai scope aktif.
  Future<void> updateTask(TaskModel task) async {
    if (task.id == null) {
      emit(const TaskError('Task tidak valid: id tidak ditemukan.'));
      return;
    }

    final validationError = _validateTask(task);
    if (validationError != null) {
      emit(TaskError(validationError));
      return;
    }

    emit(const TaskLoading());
    try {
      await _db.updateTask(task);
      await _refresh();
    } catch (e) {
      emit(TaskError('Gagal memperbarui task: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  /// Menghapus task berdasarkan [id].
  /// Setelah berhasil, melakukan refresh otomatis sesuai scope aktif.
  Future<void> deleteTask(int id) async {
    emit(const TaskLoading());
    try {
      await _db.deleteTask(id);
      await _refresh();
    } catch (e) {
      emit(TaskError('Gagal menghapus task: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE STATUS
  // ─────────────────────────────────────────────

  /// Memperbarui hanya field [status] dari sebuah task.
  /// Lebih efisien daripada [updateTask] karena tidak perlu
  /// membawa seluruh data task dari UI.
  /// Setelah berhasil, melakukan refresh otomatis sesuai scope aktif.
  Future<void> updateTaskStatus(TaskModel task, TaskStatus newStatus) async {
    if (task.id == null) {
      emit(const TaskError('Task tidak valid: id tidak ditemukan.'));
      return;
    }

    emit(const TaskLoading());
    try {
      final updated = task.copyWith(status: newStatus);
      await _db.updateTask(updated);
      await _refresh();
    } catch (e) {
      emit(TaskError('Gagal memperbarui status task: ${e.toString()}'));
    }
  }

  // ─────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────

  /// Memvalidasi field wajib pada [task].
  /// Mengembalikan pesan error sebagai String, atau null jika valid.
  String? _validateTask(TaskModel task) {
    if (task.title.trim().isEmpty) {
      return 'Judul task tidak boleh kosong.';
    }
    if (task.deadline.trim().isEmpty) {
      return 'Deadline task tidak boleh kosong.';
    }
    if (task.createdAt.trim().isEmpty) {
      return 'Created at task tidak boleh kosong.';
    }
    return null;
  }
}
