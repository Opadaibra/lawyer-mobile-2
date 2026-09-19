import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/case_controller.dart';
import '../../../data/models/case_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final caseCtrl = Get.find<CaseController>();
  late int caseId;

  @override
  void initState() {
    super.initState();
    _resolveCaseId();
    // Fetch fresh data including sub-resources
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await caseCtrl.fetchCaseById(caseId);
      caseCtrl.fetchSessions(caseId);
      caseCtrl.fetchNotes(caseId);
      caseCtrl.fetchExpenses(caseId);
      caseCtrl.fetchFees(caseId);
    });
  }

  void _resolveCaseId() {
    if (Get.arguments?['case'] is CaseModel) {
      caseId = (Get.arguments['case'] as CaseModel).id;
      // Initialize selectedCase with the passed model while we fetch fresh data
      caseCtrl.selectedCase.value = Get.arguments['case'] as CaseModel;
    } else if (Get.arguments?['id'] != null) {
      caseId = Get.arguments['id'] is int 
          ? Get.arguments['id'] 
          : int.tryParse(Get.arguments['id'].toString()) ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final actualCase = caseCtrl.selectedCase.value;

      if (actualCase == null || actualCase.id != caseId && caseCtrl.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: Text('loading'.tr)),
          body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        );
      }

      if (actualCase == null) {
        return Scaffold(
          appBar: AppBar(title: Text('error'.tr)),
          body: Center(child: Text('case_load_error'.tr)),
        );
      }

      final auth = Get.find<AuthController>();
      final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: CustomAppBar(
            title: actualCase.caseNumber,
            actions: [
              if (canMutate)
                IconButton(
                  icon: Icon(actualCase.isStarred ? Icons.star : Icons.star_outline, 
                        color: actualCase.isStarred ? Colors.amber : null),
                  onPressed: () => caseCtrl.toggleStar(actualCase.id),
                ),
              IconButton(
                icon: const Icon(Icons.article_outlined),
                onPressed: () => Get.toNamed(AppRoutes.minutes, arguments: {'caseId': actualCase.id}),
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => Get.toNamed(AppRoutes.files, arguments: {'caseId': actualCase.id}),
              ),
              if (canMutate) ...[
                // زر سريع "فصلت" - يظهر فقط إذا لم تكن القضية مغلقة
                if (actualCase.status != 'closed')
                  TextButton(
                    onPressed: () => _confirmMarkClosed(caseCtrl, actualCase.id),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('فصلت',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Get.toNamed(AppRoutes.caseForm, arguments: {'case': actualCase}),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(caseCtrl, actualCase.id),
                ),
              ],
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: 'general'.tr),
                Tab(text: 'history'.tr),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
          ),
          body: TabBarView(
            children: [
              _buildGeneralTab(context, actualCase),
              _buildHistoryTab(context, actualCase, caseCtrl, canMutate),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGeneralTab(BuildContext context, CaseModel c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(context, 'basic_info'.tr, [
            _DetailTile(Icons.tag, 'case_number'.tr, c.caseNumber),
            _DetailTile(Icons.person_outline, 'client'.tr, c.clientName ?? '---'),
            _DetailTile(Icons.subject, 'subject'.tr, c.subject ?? '---'),
            _DetailTile(Icons.account_balance_outlined, 'department'.tr, c.department ?? '---'),
            _DetailTile(Icons.info_outline, 'status'.tr, c.status),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'parties'.tr, [
            _DetailTile(Icons.person_pin_outlined, 'client_capacity'.tr, c.clientCapacity ?? '---'),
            _DetailTile(Icons.person_off_outlined, 'opponent'.tr, c.opponent ?? '---'),
            _DetailTile(Icons.person_pin_circle_outlined, 'opponent_capacity'.tr, c.opponentCapacity ?? '---'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'dates_and_notes'.tr, [
            _DetailTile(Icons.calendar_today_outlined, 'next_session_date'.tr, 
                AppHelpers.formatDateTime(c.nextSessionDate)),
            _DetailTile(Icons.notes, 'notes'.tr, c.notes ?? '---'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'fees'.tr, [
            _DetailTile(
              Icons.attach_money_outlined,
              'total_fees_agreed'.tr,
              c.feesApiAgreedTotal != null
                  ? c.feesApiAgreedTotal!.toStringAsFixed(2)
                  : '—',
            ),
            _DetailTile(
              Icons.payments_outlined,
              'total_paid_fees'.tr,
              c.feesApiPaidTotal != null
                  ? c.feesApiPaidTotal!.toStringAsFixed(2)
                  : '—',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
      BuildContext context, CaseModel c, CaseController ctrl, bool canMutate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHistorySection(
            context, 
            'sessions'.tr, 
            Icons.gavel_outlined,
            c.sessions, 
            (s) => ListTile(
              title: Text(AppHelpers.formatDateTime(s.date)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.decisions),
                  if (s.updatedBy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('آخر تعديل بواسطة: ${s.updatedBy!.name}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    )
                  else if (s.createdBy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('تم الإضافة بواسطة: ${s.createdBy!.name}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: canMutate
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.forward, size: 18, color: Colors.blue),
                          onPressed: () => _showPostponeDialog(context, ctrl, s.id, c.id),
                          tooltip: 'transfer'.tr,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => ctrl.deleteSession(s.id, c.id),
                          tooltip: 'delete'.tr,
                        ),
                      ],
                    )
                  : null,
            ),
            onAdd: () => _showAddSessionDialog(context, ctrl, c.id),
            canMutate: canMutate,
          ),
          const SizedBox(height: 16),
          _buildHistorySection(
            context, 
            'case_notes'.tr, 
            Icons.notes,
            c.caseNotes, 
            (n) => ListTile(
              title: Text(n.content),
              subtitle: Text(AppHelpers.formatDateHuman(n.date)),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => ctrl.deleteNote(n.id, c.id))
                  : null,
            ),
            onAdd: () => _showAddNoteDialog(context, ctrl, c.id),
            canMutate: canMutate,
          ),
          const SizedBox(height: 16),
           _buildHistorySection(
            context, 
            'expenses'.tr, 
            Icons.money_off_outlined,
            c.expenses, 
            (e) => ListTile(
              title: Text('${e.value} - ${e.item}'),
              subtitle: Text(AppHelpers.formatDateHuman(e.date)),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => ctrl.deleteExpense(e.id, c.id))
                  : null,
            ),
            onAdd: () => _showAddExpenseDialog(context, ctrl, c.id),
            canMutate: canMutate,
          ),
          const SizedBox(height: 16),
          _buildHistorySection(
            context, 
            'fees'.tr, 
            Icons.attach_money_outlined,
            c.fees, 
            (f) => ListTile(
              title: Text('${f.value}'),
              subtitle: Text(AppHelpers.formatDateHuman(f.date)),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => ctrl.deleteFee(f.id, c.id))
                  : null,
            ),
            onAdd: () => _showAddFeeDialog(context, ctrl, c.id),
            canMutate: canMutate,
          ),
          const SizedBox(height: 16),
          _buildHistorySection(
            context, 
            'tasks'.tr, 
            Icons.assignment_outlined,
            c.tasks ?? [], 
            (t) => ListTile(
              title: Text(t.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppHelpers.formatDateHuman(t.dueDate)),
                  if (t.updatedBy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('آخر تعديل بواسطة: ${t.updatedBy!.name}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    )
                  else if (t.createdBy != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('تم الإضافة بواسطة: ${t.createdBy!.name}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': t}))
                  : null,
            ),
            onAdd: () => Get.toNamed(AppRoutes.taskForm, arguments: {'case_id': c.id}),
            canMutate: canMutate,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHistorySection<T>(
    BuildContext context,
    String title,
    IconData icon,
    List<T> items,
    Widget Function(T) builder, {
    required VoidCallback onAdd,
    required bool canMutate,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${items.length} ${'entries'.tr}'),
        trailing: canMutate
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline), onPressed: onAdd)
            : null,
        children: items.map(builder).toList(),
      ),
    );
  }

  void _confirmMarkClosed(CaseController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('تأكيد - فصلت'),
      content: const Text('هل تريد تحديث حالة هذه الدعوى إلى "فصلت"؟'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.markAsClosed(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('فصلت'),
        ),
      ],
    ));
  }

  void _confirmDelete(CaseController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete_case'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteCase(id).then((success) { if(success) Get.back(); });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }

  // Dialogs for adding sub-resources
  void _showAddSessionDialog(BuildContext context, CaseController ctrl, int caseId) {
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final decisionCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: Text('add_session'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (context, setState) => TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'date_and_time'.tr,
                suffixIcon: const Icon(Icons.access_time),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    final combined = DateTime(
                      date.year, date.month, date.day, 
                      time.hour, time.minute
                    ).toUtc();
                    setState(() => dateCtrl.text = combined.toIso8601String().replaceFirst('T', ' ').substring(0, 19));
                  }
                }
              },
            ),
          ),
          TextField(controller: decisionCtrl, decoration: InputDecoration(labelText: 'decisions'.tr)),
          TextField(controller: noteCtrl, decoration: InputDecoration(labelText: 'notes'.tr)),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(onPressed: () {
          ctrl.addSession(caseId, {'date': dateCtrl.text, 'decisions': decisionCtrl.text, 'notes': noteCtrl.text});
          Get.back();
        }, child: Text('add'.tr)),
      ],
    ));
  }

  void _showAddNoteDialog(BuildContext context, CaseController ctrl, int caseId) {
     final noteCtrl = TextEditingController();
     Get.dialog(AlertDialog(
      title: Text('add_note'.tr),
      content: TextField(controller: noteCtrl, decoration: InputDecoration(labelText: 'notes'.tr)),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(onPressed: () {
          ctrl.addNote(caseId, {'date': DateTime.now().toIso8601String(), 'content': noteCtrl.text});
          Get.back();
        }, child: Text('add'.tr)),
      ],
    ));
  }

  void _showAddExpenseDialog(BuildContext context, CaseController ctrl, int caseId) {
    final amountCtrl = TextEditingController();
    final itemCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: Text('add_expense'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: amountCtrl, decoration: InputDecoration(labelText: 'amount'.tr), keyboardType: TextInputType.number),
          TextField(controller: itemCtrl, decoration: InputDecoration(labelText: 'item'.tr)),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(onPressed: () {
          ctrl.addExpense(caseId, {'date': DateTime.now().toIso8601String(), 'value': double.tryParse(amountCtrl.text) ?? 0, 'item': itemCtrl.text});
          Get.back();
        }, child: Text('add'.tr)),
      ],
    ));
  }

  void _showAddFeeDialog(BuildContext context, CaseController ctrl, int caseId) {
     final amountCtrl = TextEditingController();
     Get.dialog(AlertDialog(
      title: Text('add_fee'.tr),
      content: TextField(controller: amountCtrl, decoration: InputDecoration(labelText: 'amount'.tr), keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(onPressed: () {
          ctrl.addFee(caseId, {'date': DateTime.now().toIso8601String(), 'value': double.tryParse(amountCtrl.text) ?? 0});
          Get.back();
        }, child: Text('add'.tr)),
      ],
    ));
  }

  void _showPostponeDialog(BuildContext context, CaseController ctrl, int sessionId, int caseId) {
    final dateCtrl = TextEditingController();
    final decisionCtrl = TextEditingController();

    Get.dialog(AlertDialog(
      title: Text('postpone'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (context, setState) => TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'new_date'.tr,
                suffixIcon: const Icon(Icons.calendar_month),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    final combined = DateTime(
                      date.year, date.month, date.day, 
                      time.hour, time.minute
                    ).toUtc();
                    setState(() => dateCtrl.text = combined.toIso8601String().replaceFirst('T', ' ').substring(0, 19));
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: decisionCtrl, 
            decoration: InputDecoration(
              labelText: 'decisions'.tr,
              hintText: 'ماذا قررت المحكمة في هذه الجلسة؟',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        Obx(() => ctrl.isSubmitting.value
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: () async {
                  if (dateCtrl.text.isEmpty) {
                    Get.snackbar('error'.tr, 'يرجى اختيار التاريخ الجديد');
                    return;
                  }
                  // أغلق الديالوغ فوراً قبل أي عملية أخرى
                  Get.back();
                  final success = await ctrl.postponeSession(sessionId, caseId, {
                    'new_date': dateCtrl.text,
                    'decisions': decisionCtrl.text,
                  });
                  if (success) {
                    Get.snackbar(
                      'success'.tr,
                      'postpone_success'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: Text('transfer'.tr),
              )),
      ],
    ));
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      dense: true,
    );
  }
}
