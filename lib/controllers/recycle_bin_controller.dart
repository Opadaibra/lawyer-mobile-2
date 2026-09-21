import 'package:get/get.dart';
import '../data/services/api_service.dart';

class RecycleBinController extends GetxController {
  final ApiService _api = ApiService();

  final isLoading = false.obs;
  final cases = <Map<String, dynamic>>[].obs;
  final minutes = <Map<String, dynamic>>[].obs;
  final sessions = <Map<String, dynamic>>[].obs;
  final tasks = <Map<String, dynamic>>[].obs;
  final files = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecycleBin();
  }

  Future<void> fetchRecycleBin() async {
    isLoading.value = true;
    try {
      final response = await _api.get('/recycle-bin');
      final data = (response['data'] as Map<String, dynamic>?) ?? {};
      cases.value = _asMapList(data['cases']);
      minutes.value = _asMapList(data['minutes']);
      sessions.value = _asMapList(data['sessions']);
      tasks.value = _asMapList(data['tasks']);
      files.value = _asMapList(data['files']);
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> restore(String type, int id) async {
    try {
      await _api.post('/recycle-bin/$type/$id/restore');
      _removeLocal(type, id);
      Get.snackbar('نجاح', 'تمت الاستعادة بنجاح',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> forceDelete(String type, int id) async {
    try {
      await _api.delete('/recycle-bin/$type/$id');
      _removeLocal(type, id);
      Get.snackbar('نجاح', 'تم الحذف النهائي',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> emptyBin({String? type}) async {
    try {
      final endpoint =
          type == null ? '/recycle-bin/empty' : '/recycle-bin/empty?type=$type';
      await _api.delete(endpoint);
      if (type == null) {
        cases.clear();
        minutes.clear();
        sessions.clear();
        tasks.clear();
        files.clear();
      } else {
        _listFor(type).clear();
      }
      Get.snackbar('نجاح', 'تم تفريغ سلة المحذوفات',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('خطأ', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  void _removeLocal(String type, int id) {
    _listFor(type).removeWhere((e) => e['id'] == id);
  }

  RxList<Map<String, dynamic>> _listFor(String type) {
    switch (type) {
      case 'cases':
        return cases;
      case 'minutes':
        return minutes;
      case 'sessions':
        return sessions;
      case 'tasks':
        return tasks;
      case 'files':
        return files;
      default:
        return cases;
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
