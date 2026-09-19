import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/minute_model.dart';
import '../../core/constants/app_constants.dart';
import 'dashboard_controller.dart';

class MinuteController extends GetxController {
  final ApiService _api = ApiService();

  /// آخر نطاق عرض للقائمة (قضية / موكل / الكل) لإعادة التحميل بعد التعديل
  int? _minutesScopeCaseId;
  int? _minutesScopeClientId;

  final minutes = <MinuteModel>[].obs;
  final selectedMinute = Rx<MinuteModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  Future<void> fetchMinutes() async {
    _minutesScopeCaseId = null;
    _minutesScopeClientId = null;
    isLoading.value = true;
    minutes.value = [];
    try {
      final response = await _api.getList('${AppConstants.minutes}/');
      final list = _parseList(response);
      minutes.value = list.map((e) => MinuteModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMinutesByCase(int caseId) async {
    _minutesScopeCaseId = caseId;
    _minutesScopeClientId = null;
    isLoading.value = true;
    minutes.value = [];
    try {
      final response = await _api.getList('/cases/$caseId/minutes');
      final list = _parseList(response);
      minutes.value = list.map((e) => MinuteModel.fromJson(e)).toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// محاضر موكل مجمّعة حسب القضية: `GET /minutes/client/{id}/grouped`
  Future<void> fetchMinutesGroupedByClient(int clientId) async {
    _minutesScopeClientId = clientId;
    _minutesScopeCaseId = null;
    isLoading.value = true;
    minutes.value = [];
    try {
      final response =
          await _api.get('${AppConstants.minutes}/client/$clientId/grouped');
      final List<MinuteModel> flat = [];
      final int? resClientId = _toInt(response['client_id']);
      final String? resClientName = response['client_name'] as String?;
      final data = response['data'];
      if (data is! List) {
        minutes.value = [];
        return;
      }
      if (data.isEmpty) {
        minutes.value = [];
        return;
      }
      for (final groupRaw in data) {
          if (groupRaw is! Map) continue;
          final group = Map<String, dynamic>.from(groupRaw);
          final caseId = _toInt(group['case_id']);
          final caseNumber = group['case_number']?.toString();
          final court = group['court']?.toString();
          final caseType = group['case_type']?.toString();
          final minutesList = group['minutes'];
          if (minutesList is! List) continue;
          for (final raw in minutesList) {
            if (raw is! Map) continue;
            final m = Map<String, dynamic>.from(raw);
            m['case_file_id'] = m['case_file_id'] ?? caseId;
            m['case'] = {
              'case_number': caseNumber,
              'court': court,
              'case_type': caseType,
            };
            m['client_id'] = m['client_id'] ?? resClientId ?? clientId;
            m['client'] = {
              'name': resClientName,
            };
            flat.add(MinuteModel.fromJson(m));
          }
        }
      minutes.value = flat;
    } catch (e) {
      minutes.value = [];
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _reloadMinutesList() async {
    if (_minutesScopeCaseId != null) {
      await fetchMinutesByCase(_minutesScopeCaseId!);
    } else if (_minutesScopeClientId != null) {
      await fetchMinutesGroupedByClient(_minutesScopeClientId!);
    } else {
      await fetchMinutes();
    }
  }

  Future<void> fetchMinuteById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.minutes}/$id');
      final data = _extractData(response);
      selectedMinute.value = MinuteModel.fromJson(data);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<MinuteModel> minutesForCase(int caseId) =>
      minutes.where((m) => m.caseFileId == caseId).toList();

  Future<bool> createMinute(MinuteModel minute, {int? fileId}) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(AppConstants.minutes, data: minute.toCreateJson());
      
      if (fileId != null) {
        int? newId;
        if (response['data'] is List && (response['data'] as List).isNotEmpty) {
           newId = response['data'][0]['id'];
        } else if (response['data'] is Map) {
           newId = response['data']['id'];
        } else {
           newId = response['minute']?['id'] ?? response['id'];
        }
        
        if (newId != null) {
          await _api.post('/files/attach', data: {
            'file_id': fileId,
            'minute_id': newId
          });
        }
      }

      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('تم إضافة الضبط');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateMinute(int id, MinuteModel minute) async {
    isSubmitting.value = true;
    try {
      await _api.patch('${AppConstants.minutes}/$id', data: minute.toCreateJson());
      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('تم تحديث الضبط');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteMinute(int id) async {
    try {
      await _api.delete('${AppConstants.minutes}/$id');
      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('تم حذف الضبط');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<void> archiveMinute(int id) async {
    try {
      await _api.post('${AppConstants.minutes}/$id/archive');
      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('تم أرشفة الضبط');
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> unarchiveMinute(int id) async {
    try {
      await _api.post('${AppConstants.minutes}/$id/unarchive');
      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('تم إلغاء أرشفة الضبط');
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Star Toggle ──────────────────────────────────────────────────────────
  Future<void> toggleStar(int id) async {
    try {
      await _api.post('${AppConstants.minutes}/$id/star');
      await _reloadMinutesList();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      if (selectedMinute.value?.id == id) {
        await fetchMinuteById(id);
      }
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Link File ────────────────────────────────────────────────────────────
  Future<void> linkFile(int minuteId, int fileId) async {
    try {
      await _api.post('${AppConstants.minutes}/$minuteId/link-file', 
          data: {'file_id': fileId});
      _showSuccess('تم ربط الملف');
    } catch (e) {
      _showError(e);
    }
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['minutes'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  void _showError(dynamic e) {
    print('error :' + e.toString());
    Get.snackbar('Error / خطأ', e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
