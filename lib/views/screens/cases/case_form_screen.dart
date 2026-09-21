import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/case_controller.dart';
import '../../../controllers/client_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../data/models/case_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class CaseFormScreen extends StatefulWidget {
  const CaseFormScreen({super.key});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseNumCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _courtCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _clientCapCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  final _opponentCapCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  String _status = 'open';
  int? _selectedClientId;
  int? _selectedFileId;
  CaseModel? _editCase;
  double? _feesPaidFromApi;

  bool get _isEditing => _editCase != null;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args?['case'] != null) {
      _editCase = args!['case'] as CaseModel;
      _caseNumCtrl.text = _editCase!.caseNumber;
      _typeCtrl.text = _editCase!.caseType ?? '';
      _courtCtrl.text = _editCase!.court ?? '';
      _subjectCtrl.text = _editCase!.subject ?? '';
      _deptCtrl.text = _editCase!.department ?? '';
      _clientCapCtrl.text = _editCase!.clientCapacity ?? '';
      _opponentCtrl.text = _editCase!.opponent ?? '';
      _opponentCapCtrl.text = _editCase!.opponentCapacity ?? '';
      _status = _editCase!.status;
      _selectedClientId = _editCase!.clientId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeesFromApi());
    } else if (args?['clientId'] != null) {
      _selectedClientId = args!['clientId'] as int;
      _feesCtrl.text = '—';
    } else {
      _feesCtrl.text = '—';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<FileController>().fetchFiles();
    });
  }

  Future<void> _loadFeesFromApi() async {
    if (_editCase == null) return;
    final ctrl = Get.find<CaseController>();
    final totals = await ctrl.fetchFeesTotals(_editCase!.id);
    if (!mounted) return;
    if (totals != null) {
      setState(() {
        _feesCtrl.text = totals['agreed']!.toStringAsFixed(2);
        _feesPaidFromApi = totals['paid'];
      });
    } else {
      setState(() => _feesCtrl.text = '—');
    }
  }

  @override
  void dispose() {
    _caseNumCtrl.dispose();
    _typeCtrl.dispose();
    _courtCtrl.dispose();
    _subjectCtrl.dispose();
    _deptCtrl.dispose();
    _clientCapCtrl.dispose();
    _opponentCtrl.dispose();
    _opponentCapCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final caseModel = CaseModel(
      id: _editCase?.id ?? 0,
      clientId: _selectedClientId,
      caseNumber: _caseNumCtrl.text.trim(),
      caseType: _typeCtrl.text.trim().isNotEmpty ? _typeCtrl.text.trim() : null,
      court: _courtCtrl.text.trim().isNotEmpty ? _courtCtrl.text.trim() : null,
      subject:
          _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : null,
      department:
          _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : null,
      clientCapacity: _clientCapCtrl.text.trim().isNotEmpty
          ? _clientCapCtrl.text.trim()
          : null,
      opponent: _opponentCtrl.text.trim().isNotEmpty
          ? _opponentCtrl.text.trim()
          : null,
      opponentCapacity: _opponentCapCtrl.text.trim().isNotEmpty
          ? _opponentCapCtrl.text.trim()
          : null,
      totalFeesPaid: 0,
      status: _status,
    );
    final ctrl = Get.find<CaseController>();
    if (_isEditing) {
      ctrl.updateCase(_editCase!.id, caseModel);
    } else {
      ctrl.createCase(caseModel, fileId: _selectedFileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CaseController>();
    final clientCtrl = Get.find<ClientController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'edit_case'.tr : 'new_case'.tr,
        showNotification: false,
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
                      labelText: 'case_form_linked_file'.tr,
                      prefixIcon: const Icon(Icons.attach_file),
                    ),
                    items: files
                        .map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(
                                f.fileName ?? 'unknown_file'.tr,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedFileId = v),
                  ),
                );
              }),
              Obx(() {
                final clients = clientCtrl.clients;
                final items = <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('بدون موكل'),
                  ),
                  ...clients.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ];
                return DropdownButtonFormField<int?>(
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    labelText: 'client'.tr,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  items: items,
                  onChanged: (v) => setState(() => _selectedClientId = v),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caseNumCtrl,
                decoration: InputDecoration(
                  labelText: '${'case_number'.tr} *',
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (v) =>
                    AppValidators.required(v, fieldName: 'case_number'.tr),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: InputDecoration(
                  labelText: 'subject'.tr,
                  prefixIcon: const Icon(Icons.subject),
                ),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _typeCtrl,
                      decoration: InputDecoration(
                        labelText: 'case_type'.tr,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _courtCtrl,
                      decoration: InputDecoration(
                        labelText: 'court'.tr,
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('parties'.tr),
              TextFormField(
                controller: _clientCapCtrl,
                decoration: InputDecoration(
                  labelText: 'client_capacity'.tr,
                  prefixIcon: const Icon(Icons.person_pin_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opponentCtrl,
                decoration: InputDecoration(
                  labelText: 'opponent'.tr,
                  prefixIcon: const Icon(Icons.person_off_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opponentCapCtrl,
                decoration: InputDecoration(
                  labelText: 'opponent_capacity'.tr,
                  prefixIcon: const Icon(Icons.person_pin_circle_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('fees'.tr),
              TextFormField(
                controller: _feesCtrl,
                readOnly: true,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  labelText: 'total_fees_agreed'.tr,
                  helperText: 'total_fees_readonly_hint'.tr,
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                  filled: true,
                  fillColor: Theme.of(context).disabledColor.withOpacity(0.06),
                ),
              ),
              if (_feesPaidFromApi != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${'total_paid_fees'.tr}: ${_feesPaidFromApi!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'status'.tr,
                  prefixIcon: const Icon(Icons.info_outlined),
                ),
                items: AppConstants.caseStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.tr),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 32),
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
                              _isEditing ? 'update_case'.tr : 'create_case'.tr),
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
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
      ),
    );
  }
}
