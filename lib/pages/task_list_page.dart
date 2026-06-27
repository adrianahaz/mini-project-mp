import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/course_cubit.dart';
import '../cubit/course_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import 'add_task_page.dart';
import 'edit_task_page.dart';

class TaskListPage extends StatelessWidget {
  const TaskListPage({super.key});

  Future<void> _openAddTask(BuildContext context) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddTaskPage()));
    if (changed == true && context.mounted) {
      context.read<TaskCubit>().loadTasks();
      context.read<DashboardCubit>().loadSummary();
    }
  }

  Future<void> _openEditTask(BuildContext context, TaskModel task) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => EditTaskPage(task: task)));
    if (changed == true && context.mounted) {
      context.read<TaskCubit>().loadTasks();
      context.read<DashboardCubit>().loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Tugas'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<CourseCubit>().loadCourses();
          if (context.mounted) await context.read<TaskCubit>().loadTasks();
          if (context.mounted) {
            await context.read<DashboardCubit>().loadSummary();
          }
        },
        child: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            final courses = courseState is CourseLoaded
                ? courseState.courses
                : <CourseModel>[];
            return BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TaskError) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [_MessagePanel(message: state.message)],
                  );
                }
                final tasks = state is TaskLoaded ? state.tasks : <TaskModel>[];
                if (tasks.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      _MessagePanel(
                        icon: Icons.assignment_add,
                        title: 'Belum ada tugas',
                        message:
                            'Tekan tombol tambah untuk membuat tugas pertama.',
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: tasks.length + 1,
                  separatorBuilder: (_, index) =>
                      index == 0 ? const SizedBox(height: 8) : const SizedBox(),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'Daftar tugas',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      );
                    }
                    final task = tasks[index - 1];
                    final courseName = courses
                        .where((course) => course.id == task.courseId)
                        .map((course) => course.name)
                        .firstOrNull;
                    return _TaskCard(
                      task: task,
                      courseName: courseName ?? 'Course #${task.courseId}',
                      onEdit: () => _openEditTask(context, task),
                      onDelete: () => _confirmDelete(context, task),
                      onStatusChanged: (status) async {
                        await context.read<TaskCubit>().updateTaskStatus(
                          task,
                          status,
                        );
                        if (context.mounted) {
                          context.read<DashboardCubit>().loadSummary();
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Tugas "${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || task.id == null) return;
    await context.read<TaskCubit>().deleteTask(task.id!);
    if (context.mounted) context.read<DashboardCubit>().loadSummary();
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String courseName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;

  const _TaskCard({
    required this.task,
    required this.courseName,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(courseName),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            if ((task.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.event_outlined,
                  label: _formatDate(task.deadline),
                ),
                _InfoChip(
                  icon: Icons.flag_outlined,
                  label: task.priority.label,
                  color: _priorityColor(task.priority),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskStatus>(
              initialValue: task.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.sync_alt),
              ),
              items: TaskStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null && status != task.status) {
                  onStatusChanged(status);
                }
              },
            ),
          ],
        ),
      ),
    );
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Chip(
      avatar: Icon(icon, size: 18, color: chipColor),
      label: Text(label),
      side: BorderSide(color: chipColor.withValues(alpha: 0.24)),
      backgroundColor: chipColor.withValues(alpha: 0.08),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessagePanel({
    this.icon = Icons.error_outline,
    this.title = 'Terjadi kendala',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
