import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/course_model.dart';
import '../models/task_model.dart';

class DatabaseService {
  // ---------------------------------
  // SINGLETON
  // ---------------------------------

  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;

  static Database? _db;

  // ---------------------------------
  // OPEN DATABASE
  // ---------------------------------

  Completer<Database>? _dbCompleter;

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_dbCompleter != null) return _dbCompleter!.future;

    _dbCompleter = Completer<Database>();
    try {
      _db = await _openDatabase();
      _dbCompleter!.complete(_db!);
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'student_task_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------
  // CREATE TABLES
  // ---------------------------------

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id   INTEGER NOT NULL,
        title       TEXT    NOT NULL,
        description TEXT,
        priority    TEXT    NOT NULL,
        status      TEXT    NOT NULL,
        deadline    TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses (id)
          ON DELETE CASCADE
      )
    ''');
  }

  // ===============================
  // CRUD - COURSES
  // ===============================

  /// Menyimpan course baru ke database.
  /// Mengembalikan [CourseModel] dengan id yang di-generate SQLite.
  Future<CourseModel> insertCourse(CourseModel course) async {
    final db = await database;
    final id = await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return course.copyWith(id: id);
  }

  /// Mengambil semua courses, diurutkan berdasarkan nama A-Z.
  Future<List<CourseModel>> getAllCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'name ASC');
    return maps.map(CourseModel.fromMap).toList();
  }

  /// Mengambil satu course berdasarkan [id].
  /// Mengembalikan null jika tidak ditemukan.
  Future<CourseModel?> getCourseById(int id) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  /// Memperbarui data course yang sudah ada.
  /// Mengembalikan jumlah baris yang berhasil diubah.
  Future<int> updateCourse(CourseModel course) async {
    assert(course.id != null, 'Course id tidak boleh null saat update');
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// Menghapus course beserta seluruh task-nya (CASCADE).
  /// Mengembalikan jumlah baris yang berhasil dihapus.
  Future<int> deleteCourse(int id) async {
    final db = await database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // ===============================
  // CRUD - TASKS
  // ===============================

  /// Menyimpan task baru ke database
  /// Mengembalikan [TaskModel] dengan id yang di-generate SQLite.
  Future<TaskModel> insertTask(TaskModel task) async {
    final db = await database;
    final id = await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return task.copyWith(id: id);
  }

  /// Mengambil semua tasks, diurutkan berdasarkan deadline terdekat.
  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'deadline ASC');
    return maps.map(TaskModel.fromMap).toList();
  }

  /// Mengambil satu task berdasarkan [id].
  /// Mengembalikan null jika tidak ditemukan.
  Future<TaskModel?> getTaskById(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskModel.fromMap(maps.first);
  }

  /// Memperbarui data task yang sudah ada.
  /// Mengembalikan jumlah baris yang berhasil diubah.
  Future<int> updateTask(TaskModel task) async {
    assert(task.id != null, 'Task id tidak boleh null saat update');
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Menghapus task berdasarkan [id].
  /// Mengembalikan jumlah baris yang berhasil dihapus.
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ===============================
  // RELASI - TASKS BY COURSE
  // ===============================

  /// Mengambil semua tasks milik course tertentu berdasarkan [courseId].
  /// diurutkan berdasarkan deadline terdekat.
  Future<List<TaskModel>> getTasksByCourse(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  /// Mengambil tasks milik course tertentu yang difilter berdasarkan [status].
  Future<List<TaskModel>> getTasksByCourseAndStatus(
    int courseId,
    TaskStatus status,
  ) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'course_id = ? AND status = ?',
      whereArgs: [courseId, status.label],
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  // ===============================
  // DASHBOARD SUMMARY
  // ===============================

  // Mengembalikan ringkasan statistik untuk ditampilkan di dashboard:
  // - [totalTasks]     : total seluruh task
  // - [completedTasks] : task dengan status "Selesai"
  // - [pendingTasks]   : task yang belum selesai (Belum Dimulai + Sedang Dikerjakan)
  Future<DashboardSummary> getDashboardSummary() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS completed
      FROM tasks
      ''',
      [TaskStatus.selesai.label],
    );

    final total = (result.first['total'] as int?) ?? 0;
    final completed = (result.first['completed'] as int?) ?? 0;
    final pending = total - completed;

    return DashboardSummary(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
    );
  }

  // -------------------------------
  // CLOSE DATABASE
  // -------------------------------

  // Menutup koneksi database.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

// -------------------------------
// DATA CLASS - DASHBOARD SUMMARY
// -------------------------------

class DashboardSummary {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  const DashboardSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
  });

  @override
  String toString() =>
      'DashboardSummary('
      'total: $totalTasks, '
      'completed: $completedTasks, '
      'pending: $pendingTasks)';
}
