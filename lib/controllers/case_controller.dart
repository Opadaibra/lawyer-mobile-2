import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/case_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/notification_service.dart';
import '../controllers/dashboard_controller.dart';

class CaseController extends GetxController {
  final ApiService _api = ApiService();

  final cases = <CaseModel>[].obs;
  final archivedCases = <CaseModel>[].obs;
  final archivedSessions = <SessionModel>[].obs;
  final selectedCase = Rx<CaseModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final filterStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCases();
  }

  // ─── Fetch all cases ──────────────────────────────────────────────────────
  Future<void> fetchCases() async {
    isLoading.value = true;
    try {
      final response = await _api.getList('${AppConstants.cases}/');
      final list = _parseList(response);
      cases.value = list.map((e) => CaseModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Get case by ID ───────────────────────────────────────────────────────
  Future<void> fetchCaseById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.cases}/$id');
      final data = _extractData(response);
      if (data.isNotEmpty) {
        selectedCase.value = CaseModel.fromJson(data);
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Filtered cases ───────────────────────────────────────────────────────
  List<CaseModel> get filteredCases {
    if (filterStatus.value.isEmpty) return cases;
    return cases.where((c) => c.status == filterStatus.value).toList();
  }

  // ─── Create case ──────────────────────────────────────────────────────────
  Future<bool> createCase(CaseModel caseModel, {int? fileId}) async {
    isSubmitting.value = true;
    try {
      final response =
          await _api.post(AppConstants.cases, data: caseModel.toCreateJson());

      if (fileId != null) {
        final newCaseId = response['case']?['id'] ?? response['data']?['id'];
        if (newCaseId != null) {
          await _api.post('/files/attach',
              data: {'file_id': fileId, 'case_id': newCaseId});
        }
      }
      
      final newCaseId = response['case']?['id'] ?? response['data']?['id'];
      if (newCaseId != null && (caseModel.status == 'فصلت' || caseModel.status == 'closed')) {
        await _api.post('${AppConstants.cases}/$newCaseId/archive');
        await fetchArchivedCases();
      }

      await fetchCases();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('case_created'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Update case ──────────────────────────────────────────────────────────
  Future<bool> updateCase(int id, CaseModel caseModel) async {
    isSubmitting.value = true;
    try {
      await _api.patch('${AppConstants.cases}/$id',
          data: caseModel.toCreateJson());
          
      if (caseModel.status == 'فصلت' || caseModel.status == 'closed') {
        await _api.post('${AppConstants.cases}/$id/archive');
        await fetchArchivedCases();
      }

      await fetchCases();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('case_updated'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Delete case ──────────────────────────────────────────────────────────
  Future<bool> deleteCase(int id) async {
    try {
      await _api.delete('${AppConstants.cases}/$id');
      cases.removeWhere((c) => c.id == id);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('case_deleted'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  // ─── Mark case as closed (فصلت) ────────────────────────────────
  Future<bool> markAsClosed(int id) async {
    try {
      // جلب بيانات القضية الحالية
      final caseModel = cases.firstWhereOrNull((c) => c.id == id) ??
          selectedCase.value;
      if (caseModel == null) return false;
      await _api.patch('${AppConstants.cases}/$id',
          data: {...caseModel.toCreateJson(), 'status': 'closed'});
      await fetchCases();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('تمّ تحديث حالة القضية إلى فصلت');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> fetchArchivedCases() async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/?archived=true');
      final list = _parseList(response);
      archivedCases.value = list.map((e) => CaseModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Archive/Unarchive ────────────────────────────────────────────────────
  Future<void> archiveCase(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/archive');
      await fetchCases();
      await fetchArchivedCases();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('case_archived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveCase(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/unarchive');
      await fetchCases();
      await fetchArchivedCases();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('case_unarchived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Sub-resources ────────────────────────────────────────────────────────

  // Sessions
  Future<void> fetchSessions(int caseId) async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/$caseId/sessions');
      final list = _parseList(response);
      final listModels = list
          .map((e) => SessionModel.fromJson(e))
          .where((s) => !s.isArchived)
          .toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value =
            selectedCase.value!.copyWith(sessions: listModels);
      }
      NotificationService.checkSessionReminders(listModels);
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addSession(int caseId, Map<String, dynamic> data) async {
    try {
      data['case_id'] = caseId;
      data['case_file_id'] = caseId;
      await _api.post('${AppConstants.cases}/$caseId/sessions', data: data);
      await fetchSessions(caseId);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteSession(int id, int caseId) async {
    try {
      await _api.delete('/sessions/$id');
      // تحديث الواجهة فوراً
      if (selectedCase.value?.id == caseId) {
        final updated = selectedCase.value!.sessions
            .where((s) => s.id != id)
            .toList();
        selectedCase.value = selectedCase.value!.copyWith(sessions: updated);
      }
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().allSessions
            .removeWhere((s) => s.id == id);
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('session_deleted'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> postponeSession(
      int sessionId, int caseId, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      data['case_id'] = caseId;
      await _api.post('/sessions/$sessionId/postpone', data: data);
      await fetchSessions(caseId);
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().refreshDashboard();
      }
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchArchivedSessions() async {
    try {
      final response = await _api
          .getList('${AppConstants.cases}/all-sessions?archived=true');
      final list = _parseList(response);
      archivedSessions.value = list
          .map((e) => SessionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> archiveSession(int id, int caseId) async {
    try {
      await _api.post('/sessions/$id/archive');
      await fetchSessions(caseId);
      await fetchArchivedSessions();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('session_archived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveSession(int id, int caseId) async {
    try {
      await _api.post('/sessions/$id/unarchive');
      await fetchSessions(caseId);
      await fetchArchivedSessions();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('session_unarchived'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  // Notes
  Future<void> fetchNotes(int caseId) async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/$caseId/notes');
      final list = _parseList(response);
      if (list.isNotEmpty) {
        final listModels = list.map((e) => CaseNoteModel.fromJson(e)).toList();
        if (selectedCase.value?.id == caseId) {
          selectedCase.value =
              selectedCase.value!.copyWith(caseNotes: listModels);
        }
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addNote(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/notes', data: data);
      await fetchNotes(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteNote(int id, int caseId) async {
    try {
      await _api.delete('/notes/$id');
      // تحديث فوري
      if (selectedCase.value?.id == caseId) {
        final updated = selectedCase.value!.caseNotes
            .where((n) => n.id != id)
            .toList();
        selectedCase.value = selectedCase.value!.copyWith(caseNotes: updated);
      }
      _showSuccess('note_deleted'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  // Expenses
  Future<void> fetchExpenses(int caseId) async {
    try {
      final response =
          await _api.getList('${AppConstants.cases}/$caseId/expenses');
      final list = _parseList(response);
      if (list.isNotEmpty) {
        final listModels = list.map((e) => ExpenseModel.fromJson(e)).toList();
        if (selectedCase.value?.id == caseId) {
          selectedCase.value =
              selectedCase.value!.copyWith(expenses: listModels);
        }
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> addExpense(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/expenses', data: data);
      await fetchExpenses(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteExpense(int id, int caseId) async {
    try {
      await _api.delete('/expenses/$id');
      // تحديث فوري
      if (selectedCase.value?.id == caseId) {
        final updated = selectedCase.value!.expenses
            .where((e) => e.id != id)
            .toList();
        selectedCase.value = selectedCase.value!.copyWith(expenses: updated);
      }
      _showSuccess('expense_deleted'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  // Fees — يدعم `data` كقائمة أو ككائن { total_fees, total_paid, fees_records }
  Future<void> fetchFees(int caseId) async {
    try {
      final response = await _api.get('${AppConstants.cases}/$caseId/fees');
      final raw = response['data'];
      if (raw == null) return;

      double? agreed;
      double? paid;
      List<dynamic> listRaw = [];

      if (raw is List) {
        listRaw = raw;
        double sum = 0;
        for (var item in listRaw) {
          if (item is Map) {
            sum += _parseMoney(item['value']);
          }
        }
        agreed = sum;
        paid = sum;
      } else if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        agreed = _parseMoney(m['total_fees']);
        paid = _parseMoney(m['total_paid']);
        final rec = m['fees_records'];
        if (rec is List) {
          listRaw = rec;
        }
      }

      if (listRaw.isEmpty && agreed == 0 && paid == 0) return;

      final listModels = listRaw
          .map((e) => FeeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (selectedCase.value?.id == caseId) {
        selectedCase.value = selectedCase.value!.copyWith(
          fees: listModels,
          feesApiAgreedTotal: agreed,
          feesApiPaidTotal: paid,
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  double _parseMoney(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// إجمالي الأتعاب والمسدّد من `GET .../cases/{id}/fees` (لعرض النموذج).
  Future<Map<String, double>?> fetchFeesTotals(int caseId) async {
    try {
      final response = await _api.get('${AppConstants.cases}/$caseId/fees');
      final raw = response['data'];
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        return {
          'agreed': _parseMoney(m['total_fees']),
          'paid': _parseMoney(m['total_paid']),
        };
      } else if (raw is List) {
        double total = 0;
        for (var item in raw) {
          if (item is Map) {
            total += _parseMoney(item['value']);
          }
        }
        return {
          'agreed': total,
          'paid': total,
        };
      }
    } catch (_) {}
    return null;
  }

  Future<bool> addFee(int caseId, Map<String, dynamic> data) async {
    try {
      await _api.post('${AppConstants.cases}/$caseId/fees', data: data);
      await fetchFees(caseId);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> deleteFee(int id, int caseId) async {
    try {
      await _api.delete('/fees/$id');
      // تحديث فوري
      if (selectedCase.value?.id == caseId) {
        final updated = selectedCase.value!.fees
            .where((f) => f.id != id)
            .toList();
        selectedCase.value = selectedCase.value!.copyWith(fees: updated);
      }
      _showSuccess('fee_deleted'.tr);
    } catch (e) {
      _showError(e);
    }
  }

  // Star Toggle
  Future<void> toggleStar(int id) async {
    try {
      await _api.post('${AppConstants.cases}/$id/star');
      if (selectedCase.value?.id == id) {
        await fetchCaseById(id);
      }
      await fetchCases();
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['cases'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  void _showError(dynamic e) {
    Get.snackbar(
      'error'.tr,
      e.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccess(String msg) {
    Get.snackbar('success'.tr, msg, snackPosition: SnackPosition.BOTTOM);
  }
}
