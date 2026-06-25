import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/database_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DatabaseService _db;

  DashboardCubit({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService.instance,
      super(const DashboardInitial());

  // ---------------------------------
  // LOAD SUMMARY
  // ---------------------------------

  /// Memuat ringkasan statistik task dari database:
  /// - totalTasks      : jumlah seluruh task
  /// - completedTasks  : task dengan status "Selesai"
  /// - pendingTasks    : task yang belum selesai
  ///
  /// Dipanggil saat halaman dashboard dibuka atau setelah
  /// operasi CRUD task selesai (agar angka selalu sinkron).
  Future<void> loadSummary() async {
    emit(const DashboardLoading());
    try {
      final summary = await _db.getDashboardSummary();
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError('Gagal memuat ringkasan dashboard: ${e.toString()}'));
    }
  }
}
