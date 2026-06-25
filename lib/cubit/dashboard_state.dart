import 'package:equatable/equatable.dart';

import '../services/database_service.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum ada aksi apapun.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// State saat data sedang dimuat dari database.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// State saat data ringkasan berhasil dimuat.
/// Membawa [DashboardSummary] dari DatabaseService.
class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;

  const DashboardLoaded(this.summary);

  /// Shortcut getter agar UI tidak perlu akses via summary.xxx
  int get totalTasks => summary.totalTasks;
  int get completedTasks => summary.completedTasks;
  int get pendingTasks => summary.pendingTasks;

  @override
  List<Object?> get props => [
    summary.totalTasks,
    summary.completedTasks,
    summary.pendingTasks,
  ];
}

/// State saat terjadi error pada saat memuat data.
class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
