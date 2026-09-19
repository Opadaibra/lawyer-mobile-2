import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/case_model.dart';
import '../../../data/models/file_model.dart';
import '../../../data/models/sub_resource_models.dart';
import '../../../data/services/api_service.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';

/// تفاصيل قضية لعرض الموكل؛ الأتعاب من `GET /client-portal/fees`.
class ClientPortalCaseDetailScreen extends StatefulWidget {
  const ClientPortalCaseDetailScreen({super.key});

  @override
  State<ClientPortalCaseDetailScreen> createState() =>
      _ClientPortalCaseDetailScreenState();
}

class _ClientPortalCaseDetailScreenState
    extends State<ClientPortalCaseDetailScreen> {
  CaseModel? _case;
  bool _loadingFees = true;
  String? _feesError;
  double? _portalTotalFees;
  double? _portalTotalPaid;
  final List<FeeModel> _caseFeeRecords = [];

  @override
  void initState() {
    super.initState();
    final c = Get.arguments?['case'];
    if (c is CaseModel) _case = c;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPortalFees());
  }

  double _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Future<void> _loadPortalFees() async {
    final c = _case;
    if (c == null) {
      setState(() => _loadingFees = false);
      return;
    }
    try {
      final api = ApiService();
      final res = await api.get(AppConstants.clientPortalFees);
      final raw = res['data'];
      _portalTotalFees = null;
      _portalTotalPaid = null;
      _caseFeeRecords.clear();
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        _portalTotalFees = _parseMoney(m['total_fees']);
        _portalTotalPaid = _parseMoney(m['total_paid']);
        final rec = m['fees_records'];
        if (rec is List) {
          for (final e in rec) {
            final fm =
                FeeModel.fromJson(Map<String, dynamic>.from(e as Map));
            if (fm.caseId == c.id) {
              _caseFeeRecords.add(fm);
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _loadingFees = false;
          _feesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingFees = false;
          _feesError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  double get _casePaidSum =>
      _caseFeeRecords.fold<double>(0, (a, f) => a + f.value);

  @override
  Widget build(BuildContext context) {
    final c = _case;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text('details'.tr)),
        body: Center(child: Text('portal_case_missing'.tr)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('details'.tr),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(context, c),
            const SizedBox(height: 16),
            _portalFeesCard(),
            const SizedBox(height: 20),
            _sectionTitle('basic_info'.tr),
            _infoCard(context, c),
            const SizedBox(height: 20),
            _sectionTitle('sessions'.tr),
            _sessionsCard(c),
            const SizedBox(height: 20),
            _sectionTitle('minutes'.tr),
            _minutesCard(c),
            const SizedBox(height: 20),
            _sectionTitle('tasks'.tr),
            _tasksCard(c),
            const SizedBox(height: 20),
            _sectionTitle('files'.tr),
            _filesCard(c),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context, CaseModel c) {
    final statusColor = _statusColor(c.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_open, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'case_number'.tr} ${c.caseNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (c.caseType != null && c.caseType!.isNotEmpty)
                    Text(
                      c.caseType!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusLabel(c.status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _portalFeesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'fees'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingFees)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_feesError != null)
              Text(
                _feesError!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              )
            else ...[
              Text(
                'portal_fees_all_cases'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${'total_fees_agreed'.tr}: ${_portalTotalFees?.toStringAsFixed(2) ?? '—'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'total_paid_fees'.tr}: ${_portalTotalPaid?.toStringAsFixed(2) ?? '—'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                'fees_paid_for_this_case'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _casePaidSum.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_caseFeeRecords.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'portal_fees_records_title'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._caseFeeRecords.map((f) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_outlined, size: 20),
                    title: Text(
                      f.value.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        AppHelpers.formatDateHuman(f.date),
                        if (f.notes != null && f.notes!.trim().isNotEmpty)
                          f.notes!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, CaseModel c) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            if (c.subject != null && c.subject!.isNotEmpty)
              _tile(Icons.subject_outlined, 'subject'.tr, c.subject!),
            if (c.court != null && c.court!.isNotEmpty)
              _tile(Icons.account_balance_outlined, 'court'.tr, c.court!),
            if (c.department != null && c.department!.isNotEmpty)
              _tile(Icons.meeting_room_outlined, 'department'.tr, c.department!),
            if (c.clientCapacity != null && c.clientCapacity!.isNotEmpty)
              _tile(Icons.person_outline, 'client_capacity'.tr, c.clientCapacity!),
            if (c.opponent != null && c.opponent!.isNotEmpty)
              _tile(Icons.person_off_outlined, 'opponent'.tr, c.opponent!),
            if (c.opponentCapacity != null && c.opponentCapacity!.isNotEmpty)
              _tile(Icons.badge_outlined, 'opponent_capacity'.tr, c.opponentCapacity!),
            if (c.notes != null && c.notes!.isNotEmpty)
              _tile(Icons.notes_outlined, 'notes'.tr, c.notes!),
            if (c.createdAt != null)
              _tile(
                Icons.calendar_today_outlined,
                'member_since'.tr,
                AppHelpers.formatDateHuman(c.createdAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle:
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sessionsCard(CaseModel c) {
    if (c.sessions.isEmpty) {
      return _emptyBox('no_sessions'.tr);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.sessions.map((s) {
          return ListTile(
            leading: const Icon(Icons.gavel_outlined, color: AppTheme.accent),
            title: Text(
              AppHelpers.formatDateHuman(s.date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.decisions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${'decisions'.tr}: ${s.decisions}'),
                  ),
                if (s.notes != null && s.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${'notes'.tr}: ${s.notes}'),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _minutesCard(CaseModel c) {
    if (c.minutes.isEmpty) {
      return _emptyBox('no_minutes_for_client'.tr);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.minutes.map((m) {
          return ListTile(
            leading: const Icon(Icons.article_outlined, color: AppTheme.primary),
            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              AppHelpers.formatDateHuman(
                  m.date.isNotEmpty ? m.date : m.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Get.toNamed(AppRoutes.minuteDetail,
                arguments: {'minute': m}),
          );
        }).toList(),
      ),
    );
  }

  Widget _tasksCard(CaseModel c) {
    if (c.tasks.isEmpty) {
      return _emptyBox('no_tasks'.tr);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.tasks.map((t) {
          return ListTile(
            leading: Icon(
              t.status == 'completed'
                  ? Icons.check_circle_outline
                  : Icons.task_alt_outlined,
              color: AppTheme.getStatusColor(t.status),
            ),
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              t.dueDate != null
                  ? '${'task_due_date'.tr}: ${AppHelpers.formatDateTime(t.dueDate)} · ${t.status.tr}'
                  : t.status.tr,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filesCard(CaseModel c) {
    if (c.linkedFiles.isEmpty) {
      return _emptyBox('portal_attachments_empty'.tr);
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.linkedFiles.map((f) {
          return ListTile(
            leading: Icon(
              AppHelpers.getFileIcon(f.displayName),
              color: AppTheme.primary,
            ),
            title: Text(
              f.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: f.size != null
                ? Text(AppHelpers.formatFileSize(f.size!),
                    style: const TextStyle(fontSize: 11))
                : null,
            trailing: const Icon(Icons.open_in_new_outlined),
            onTap: () => _openFile(f),
          );
        }).toList(),
      ),
    );
  }

  void _openFile(FileModel f) {
    if (f.absoluteUrl == null) {
      Get.snackbar('important'.tr, 'portal_file_no_url'.tr);
      return;
    }
    Get.toNamed(AppRoutes.fileViewer, arguments: {'file': f});
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.statusOpen;
      case 'closed':
        return AppTheme.statusClosed;
      case 'pending':
        return AppTheme.statusPending;
      case 'archived':
        return AppTheme.statusArchived;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'open'.tr;
      case 'closed':
        return 'closed'.tr;
      case 'pending':
        return 'pending'.tr;
      case 'archived':
        return 'archived'.tr;
      default:
        return status;
    }
  }
}
