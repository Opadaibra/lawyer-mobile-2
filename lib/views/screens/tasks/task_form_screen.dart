import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/task_controller.dart';
import '../../../controllers/case_controller.dart';
import '../../../data/models/task_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = 'pending';
  int? _selectedCaseId;
  DateTime? _dueDate;
  TaskModel? _editTask;

  bool get _isEditing => _editTask != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['task'] != null) {
      _editTask = args!['task'] as TaskModel;
      _titleCtrl.text = _editTask!.title;
      _descCtrl.text = _editTask!.description ?? '';
      _status = _editTask!.status;
      _selectedCaseId = _editTask!.caseFileId;
      if (_editTask!.dueDate != null) {
        final dueUtc = AppHelpers.dueInstantUtc(_editTask!.dueDate);
        if (dueUtc != null) {
          _dueDate = dueUtc.toLocal();
        }
      }
    } else if (args?['case_id'] != null) {
      _selectedCaseId = args!['case_id'] as int;
    } else if (args?['caseId'] != null) {
      _selectedCaseId = args!['caseId'] as int;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _dueDate != null
            ? TimeOfDay.fromDateTime(_dueDate!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() => _dueDate = pickedDate);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final task = TaskModel(
      id: _editTask?.id ?? 0,
      caseFileId: _selectedCaseId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      dueDate: _dueDate?.toUtc().toIso8601String(),
      status: _status,
    );
    final ctrl = Get.find<TaskController>();
    if (_isEditing) {
      ctrl.updateTask(_editTask!.id, task);
    } else {
      ctrl.createTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TaskController>();
    final caseCtrl = Get.find<CaseController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'task_edit_title'.tr : 'new_task'.tr,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Obx(() {
                final cases = caseCtrl.cases;
                return DropdownButtonFormField<int>(
                  value: _selectedCaseId,
                  decoration: InputDecoration(
                    labelText: 'task_form_case_optional'.tr,
                    prefixIcon: const Icon(Icons.folder_outlined),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                        value: null, child: Text('no_case_linked'.tr)),
                    ...cases.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.clientName ?? ""} - ${c.caseNumber}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCaseId = v),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'task_title_label'.tr,
                  prefixIcon: const Icon(Icons.task_outlined),
                ),
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'field_title_required'.tr),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'task_description'.tr,
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE0E7FF), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? AppHelpers.formatDateTime(
                                  _dueDate!.toUtc().toIso8601String())
                              : 'due_date_time_placeholder'.tr,
                          style: TextStyle(
                              color: _dueDate != null
                                  ? null
                                  : Colors.grey[500]),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'status'.tr,
                  prefixIcon: const Icon(Icons.info_outlined),
                ),
                items: AppConstants.taskStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(AppHelpers.taskStatusArabic(s)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isSubmitting.value ? null : _submit,
                      child: ctrl.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isEditing ? 'save'.tr : 'create_task_button'.tr),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
