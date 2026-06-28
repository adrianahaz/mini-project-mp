import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../models/task_model.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<TaskCubit>().loadTasks(),
      child: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [_Panel(child: Text(state.message))],
            );
          }
          final tasks = state is TaskLoaded ? state.tasks : <TaskModel>[];
          final total = tasks.length;
          final done = tasks
              .where((task) => task.status == TaskStatus.selesai)
              .length;
          final pending = total - done;
          final donePercent = total == 0 ? 0.0 : done / total;
          final pendingPercent = total == 0 ? 0.0 : pending / total;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Statistik',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress tugas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressRow(
                      label: 'Selesai',
                      value: donePercent,
                      count: done,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 12),
                    _ProgressRow(
                      label: 'Belum selesai',
                      value: pendingPercent,
                      count: pending,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berdasarkan prioritas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TaskPriority.values.map(
                      (priority) => _CountTile(
                        label: priority.label,
                        count: tasks
                            .where((task) => task.priority == priority)
                            .length,
                        color: _priorityColor(priority),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berdasarkan status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...TaskStatus.values.map(
                      (status) => _CountTile(
                        label: status.label,
                        count: tasks
                            .where((task) => task.status == status)
                            .length,
                        color: _statusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.rendah => const Color(0xFF059669),
      TaskPriority.sedang => const Color(0xFFF59E0B),
      TaskPriority.tinggi => const Color(0xFFDC2626),
    };
  }

  static Color _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.belumDimulai => const Color(0xFF64748B),
      TaskStatus.sedangDikerjakan => const Color(0xFF2563EB),
      TaskStatus.selesai => const Color(0xFF059669),
    };
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final int count;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$count tugas ($percent%)'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          minHeight: 10,
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountTile({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.circle, size: 12, color: color),
      ),
      title: Text(label),
      trailing: Text(
        '$count',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
