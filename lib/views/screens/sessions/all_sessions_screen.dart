import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lawyer_client/controllers/case_controller.dart';

import '../../../app/routes/app_routes.dart';

import '../../../controllers/dashboard_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/sub_resource_models.dart';
import '../../widgets/custom_app_bar.dart';

/// كل الجلسات من `GET /cases/all-sessions` — يبرز اسم الموكل.
class AllSessionsScreen extends StatelessWidget {
  const AllSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'sessions'.tr,
        showNotification: true,
      ),
      body: Obx(() {
        final list = dash.allSessions;
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => dash.reloadAllSessions(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Center(
                    child: Text(
                      'no_sessions'.tr,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => dash.reloadAllSessions(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = list[i];
              return _SessionCard(session: s);
            },
          ),
        );
      }),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final clientLabel = session.clientName?.trim().isNotEmpty == true
        ? session.clientName!.trim()
        : 'client'.tr;
    final caseLine = [
      if (session.caseNumber != null && session.caseNumber!.isNotEmpty)
        session.caseNumber,
      if (session.court != null && session.court!.isNotEmpty) session.court,
    ].whereType<String>().join(' · ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(
          AppRoutes.caseDetail,
          arguments: {'id': session.caseId},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (session.updatedBy != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('آخر تعديل بواسطة: ${session.updatedBy!.name}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          )
                        else if (session.createdBy != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('تم الإضافة بواسطة: ${session.createdBy!.name}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        Text(
                          clientLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        if (caseLine.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            caseLine,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.event, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          AppHelpers.formatDateTime(session.date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showPostponeDialog(context, session),
                    icon: const Icon(Icons.forward, size: 16),
                    label: Text('transfer'.tr,
                        style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (session.decisions.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  session.decisions,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
              ],
              if (session.notes != null &&
                  session.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  session.notes!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPostponeDialog(BuildContext context, SessionModel s) {
    final dateCtrl = TextEditingController();
    final decisionCtrl = TextEditingController();
    final caseCtrl = Get.find<CaseController>();

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
                    final combined = DateTime(date.year, date.month, date.day,
                            time.hour, time.minute)
                        .toUtc();
                    setState(() => dateCtrl.text = combined
                        .toIso8601String()
                        .replaceFirst('T', ' ')
                        .substring(0, 19));
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
        Obx(() => caseCtrl.isSubmitting.value
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
                  final success = await caseCtrl.postponeSession(s.id, s.caseId, {
                    'new_date': dateCtrl.text,
                    'decisions': decisionCtrl.text,
                  });
                  // ملاحظة: postponeSession يستدعي refreshDashboard من الداخل - لا حاجة لاستدعائه مرة ثانية
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
