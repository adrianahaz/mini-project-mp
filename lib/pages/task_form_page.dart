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

class TaskFormPage extends StatefulWidget {
  final TaskModel? task;

  const TaskFormPage({super.key, this.task});

  bool get isEditing => task != null;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  int? _courseId;
  TaskPriority _priority = TaskPriority.sedang;
  TaskStatus _status = TaskStatus.belumDimulai;
  DateTime _deadline = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _courseId = task?.courseId;
    _priority = task?.priority ?? TaskPriority.sedang;
    _status = task?.status ?? TaskStatus.belumDimulai;
    _deadline = DateTime.tryParse(task?.deadline ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_courseId == null) {
      _showMessage('Pilih mata kuliah terlebih dahulu.');
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();
    final task = TaskModel(
      id: widget.task?.id,
      courseId: _courseId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      deadline: DateFormat('yyyy-MM-dd').format(_deadline),
      createdAt: widget.task?.createdAt ?? now,
    );

    final taskCubit = context.read<TaskCubit>();
    if (widget.isEditing) {
      await taskCubit.updateTask(task);
    } else {
      await taskCubit.addTask(task);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    final state = taskCubit.state;
    if (state is TaskError) {
      _showMessage(state.message);
      return;
    }
    context.read<DashboardCubit>().loadSummary();
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _addCourse() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah mata kuliah'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama mata kuliah',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;

    await context.read<CourseCubit>().addCourse(name);
    if (!mounted) return;
    final state = context.read<CourseCubit>().state;
    if (state is CourseError) {
      _showMessage(state.message);
      return;
    }
    final courses = state is CourseLoaded ? state.courses : <CourseModel>[];
    final newCourse = courses.where((course) => course.name == name.trim());
    if (newCourse.isNotEmpty) {
      setState(() => _courseId = newCourse.last.id);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit tugas' : 'Tambah tugas'),
      ),
      body: BlocListener<CourseCubit, CourseState>(
        listener: (context, state) {
          if (state is CourseError) _showMessage(state.message);
        },
        child: BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            final courses = courseState is CourseLoaded
                ? courseState.courses
                : <CourseModel>[];
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nama tugas',
                      prefixIcon: Icon(Icons.assignment_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Nama tugas wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue:
                              courses.any((course) => course.id == _courseId)
                              ? _courseId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Mata kuliah',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: courses
                              .where((course) => course.id != null)
                              .map(
                                (course) => DropdownMenuItem(
                                  value: course.id,
                                  child: Text(course.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _courseId = value),
                          validator: (value) => value == null
                              ? 'Mata kuliah wajib dipilih.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Tambah mata kuliah',
                        onPressed: _addCourse,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioritas',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: TaskPriority.values
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _priority = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
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
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _pickDeadline,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Deadline',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_deadline)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.isEditing ? 'Simpan perubahan' : 'Simpan',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
