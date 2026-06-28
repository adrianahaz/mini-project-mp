import 'package:flutter/material.dart';

import '../models/task_model.dart';
import 'task_form_page.dart';

class EditTaskPage extends StatelessWidget {
  final TaskModel task;

  const EditTaskPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return TaskFormPage(task: task);
  }
}
