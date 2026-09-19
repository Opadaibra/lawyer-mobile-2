import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/minute_controller.dart';
import '../../../controllers/case_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../data/models/minute_model.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app/routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';

class MinuteFormScreen extends StatefulWidget {
  const MinuteFormScreen({super.key});

  @override
  State<MinuteFormScreen> createState() => _MinuteFormScreenState();
}

class _MinuteFormScreenState extends State<MinuteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _numCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _clientCapCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  final _opponentCapCtrl = TextEditingController();
  final _lastProcCtrl = TextEditingController();
  
  int? _selectedCaseId;
  int? _selectedFileId;
  MinuteModel? _editMinute;

  bool get _isEditing => _editMinute != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['minute'] != null) {
      _editMinute = args!['minute'] as MinuteModel;
      _titleCtrl.text = _editMinute!.title;
      _contentCtrl.text = _editMinute!.content ?? '';
      _dateCtrl.text = _editMinute!.date ?? DateTime.now().toIso8601String().split('T')[0];
      _numCtrl.text = _editMinute!.minuteNumber ?? '';
      _deptCtrl.text = _editMinute!.department ?? '';
      _clientCapCtrl.text = _editMinute!.clientCapacity ?? '';
      _opponentCtrl.text = _editMinute!.opponent ?? '';
      _opponentCapCtrl.text = _editMinute!.opponentCapacity ?? '';
      _lastProcCtrl.text = _editMinute!.lastProcedure ?? '';
      _selectedCaseId = _editMinute!.caseFileId;
    } else if (args?['caseId'] != null) {
      _selectedCaseId = args!['caseId'] as int;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _dateCtrl.dispose();
    _numCtrl.dispose();
    _deptCtrl.dispose();
    _clientCapCtrl.dispose();
    _opponentCtrl.dispose();
    _opponentCapCtrl.dispose();
    _lastProcCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final minute = MinuteModel(
      id: _editMinute?.id ?? 0,
      caseFileId: _selectedCaseId,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim().isNotEmpty ? _contentCtrl.text.trim() : null,
      date: _dateCtrl.text.trim(),
      minuteNumber: _numCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
      clientCapacity: _clientCapCtrl.text.trim(),
      opponent: _opponentCtrl.text.trim(),
      opponentCapacity: _opponentCapCtrl.text.trim(),
      lastProcedure: _lastProcCtrl.text.trim(),
    );
    final ctrl = Get.find<MinuteController>();
    if (_isEditing) {
      ctrl.updateMinute(_editMinute!.id, minute);
    } else {
      ctrl.createMinute(minute, fileId: _selectedFileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MinuteController>();
    final caseCtrl = Get.find<CaseController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'edit_minute'.tr : 'new_minute'.tr,
        showNotification: false,
        actions: _isEditing ? [
           IconButton(
            icon: Icon(Icons.star_outline), // Should be dynamic
            onPressed: () => ctrl.toggleStar(_editMinute!.id),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => Get.toNamed(AppRoutes.files, arguments: {'minuteId': _editMinute!.id}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(ctrl, _editMinute!.id),
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final fileCtrl = Get.find<FileController>();
                final files = fileCtrl.files;
                if (files.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    value: _selectedFileId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: ' ملف (اختياري)',
                      prefixIcon: const Icon(Icons.attach_file),
                    ),
                    items: files
                        .map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(
                                f.fileName ?? 'ملف غير معروف',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFileId = v),
                  ),
                );
              }),
              // Case dropdown  (optional)
              Obx(() {
                final cases = caseCtrl.cases;
                return DropdownButtonFormField<int>(
                  value: _selectedCaseId,
                  decoration: InputDecoration(
                    labelText: 'case'.tr + ' (اختياري)',
                    prefixIcon: const Icon(Icons.folder_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('بدون قضية'),
                    ),
                    ...cases.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.caseNumber),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCaseId = v),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateCtrl,
                      decoration: InputDecoration(
                        labelText: 'date'.tr,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _numCtrl,
                      decoration: InputDecoration(
                        labelText: 'minute_number'.tr,
                        prefixIcon: const Icon(Icons.tag),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'title'.tr + ' *',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) => AppValidators.required(v, fieldName: 'title'.tr),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deptCtrl,
                decoration: InputDecoration(
                  labelText: 'department'.tr,
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('parties'.tr),
              TextFormField(
                controller: _clientCapCtrl,
                decoration: InputDecoration(label: Text('client_capacity'.tr)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opponentCtrl,
                decoration: InputDecoration(label: Text('opponent'.tr)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opponentCapCtrl,
                decoration: InputDecoration(label: Text('opponent_capacity'.tr)),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('procedures'.tr),
              TextFormField(
                controller: _lastProcCtrl,
                decoration: InputDecoration(
                  labelText: 'last_procedure'.tr,
                  prefixIcon: const Icon(Icons.history),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'content'.tr,
                  prefixIcon: const Icon(Icons.article_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isSubmitting.value ? null : _submit,
                      child: ctrl.isSubmitting.value
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_isEditing
                              ? 'update_minute'.tr
                              : 'create_minute'.tr),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
      ),
    );
  }

  void _confirmDelete(MinuteController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteMinute(id).then((success) { if(success) Get.back(); });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }
}
