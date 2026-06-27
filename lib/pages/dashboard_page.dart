import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../models/task_model.dart';
import 'add_task_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _openAddTask(BuildContext context) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddTaskPage()));
    if (changed == true && context.mounted) {
      context.read<TaskCubit>().loadTasks();
      context.read<DashboardCubit>().loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<TaskCubit>().loadTasks();
        if (context.mounted) await context.read<DashboardCubit>().loadSummary();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ringkasan tugas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openAddTask(context),
                icon: const Icon(Icons.add),
                label: const Text('Tugas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is DashboardError) {
                return _ErrorPanel(message: state.message);
              }
              final total = state is DashboardLoaded ? state.totalTasks : 0;
              final done = state is DashboardLoaded ? state.completedTasks : 0;
              final pending = state is DashboardLoaded ? state.pendingTasks : 0;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.sizeOf(context).width > 640 ? 4 : 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _SummaryCard(
                    label: 'Total',
                    value: total,
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF2563EB),
                  ),
                  _SummaryCard(
                    label: 'Selesai',
                    value: done,
                    icon: Icons.task_alt,
                    color: const Color(0xFF059669),
                  ),
                  _SummaryCard(
                    label: 'Belum selesai',
                    value: pending,
                    icon: Icons.hourglass_bottom,
                    color: const Color(0xFFF59E0B),
                  ),
                  BlocBuilder<TaskCubit, TaskState>(
                    builder: (context, taskState) {
                      final tasks = taskState is TaskLoaded
                          ? taskState.tasks
                          : <TaskModel>[];
                      final near = tasks.where(_isNearDeadline).length;
                      return _SummaryCard(
                        label: 'Dekat deadline',
                        value: near,
                        icon: Icons.event_busy_outlined,
                        color: const Color(0xFFDC2626),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Deadline terdekat',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          BlocBuilder<TaskCubit, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is TaskError) {
                return _ErrorPanel(message: state.message);
              }
              final tasks = state is TaskLoaded
                  ? state.tasks
                        .where((task) => task.status != TaskStatus.selesai)
                        .take(5)
                        .toList()
                  : <TaskModel>[];
              if (tasks.isEmpty) {
                return const _EmptyPanel(
                  icon: Icons.celebration_outlined,
                  title: 'Belum ada deadline aktif',
                  subtitle: 'Tambahkan tugas untuk mulai mengatur jadwal.',
                );
              }
              return Column(
                children: tasks
                    .map(
                      (task) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _priorityColor(
                              task.priority,
                            ).withValues(alpha: 0.12),
                            child: Icon(
                              Icons.flag_outlined,
                              color: _priorityColor(task.priority),
                            ),
                          ),
                          title: Text(task.title),
                          subtitle: Text(_formatDate(task.deadline)),
                          trailing: Text(task.priority.label),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static bool _isNearDeadline(TaskModel task) {
    final date = DateTime.tryParse(task.deadline);
    if (date == null || task.status == TaskStatus.selesai) return false;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 3));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd MMM yyyy').format(date);
  }

  static Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.rendah => const Color(0xFF059669),
      TaskPriority.sedang => const Color(0xFFF59E0B),
      TaskPriority.tinggi => const Color(0xFFDC2626),
    };
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C))),
      ),
    );
  }
}
