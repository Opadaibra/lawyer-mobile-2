import 'package:get/get.dart';
import 'package:lawyer_client/data/services/storage_service.dart';
import '../data/services/api_service.dart';
import '../core/constants/app_constants.dart';
import 'auth_controller.dart';

class TeamController extends GetxController {
  final ApiService _api = ApiService();

  final members = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.team);
      List<Map<String, dynamic>> list = [];
      if (response is Map && response['data'] is List) {
        list = List<Map<String, dynamic>>.from(response['data']);
      } else if (response is List) {
        list = List<Map<String, dynamic>>.from(response);
      }
      // إخفاء الـ CLIENT من قائمة الفريق
      members.value = list.where((m) => m['role']?.toString().toUpperCase() != 'CLIENT').toList();
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addMember({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final u = Get.find<AuthController>().currentUser.value;
    if (!StorageService.isOfflineMode() && u?.canMutateOfficeContent != true) {
      Get.snackbar('error'.tr, 'viewer_no_edit_permission'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      await _api.post(AppConstants.team, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      await fetchMembers();
      _showSuccess('done'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateMember({
    required int id,
    String? name,
    String? email,
    String? role,
  }) async {
    if (StorageService.isOfflineMode()) {
      Get.snackbar(
          'error'.tr, 'لا يمكن تعديل معلومات الفريق في وضع عدم الاتصال',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    // فقط المدير يمكنه تعديل بيانات الأعضاء
    final u = Get.find<AuthController>().currentUser.value;
    if (u?.role?.toUpperCase() != 'MANAGER') {
      Get.snackbar('error'.tr, 'صلاحية تعديل بيانات الفريق متاحة للمدير فقط',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (role != null) data['role'] = role;
      await _api.put('${AppConstants.team}/$id', data: data);
      await fetchMembers();
      _showSuccess('تم التعديل بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> changeMemberPassword(int id, String newPassword) async {
    if (StorageService.isOfflineMode()) {
      Get.snackbar('error'.tr, 'لا يمكن تغيير كلمة المرور في وضع عدم الاتصال',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    // فقط المدير يمكنه تغيير كلمة مرور أعضاء الفريق
    final u = Get.find<AuthController>().currentUser.value;
    if (u?.role?.toUpperCase() != 'MANAGER') {
      Get.snackbar('error'.tr, 'صلاحية تغيير كلمة المرور متاحة للمدير فقط',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      await _api.put('${AppConstants.team}/$id/change-password', data: {
        'password': newPassword,
        'password_confirmation': newPassword,
      });
      _showSuccess('تم تغيير كلمة المرور بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> removeMember(int id) async {
    if (StorageService.isOfflineMode()) {
      Get.snackbar('error'.tr, 'لا يمكن حذف عضو من الفريق في وضع عدم الاتصال',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    // فقط المدير يمكنه حذف أعضاء الفريق
    final u = Get.find<AuthController>().currentUser.value;
    if (u?.role?.toUpperCase() != 'MANAGER') {
      Get.snackbar('error'.tr, 'صلاحية حذف الأعضاء متاحة للمدير فقط',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    try {
      await _api.delete('${AppConstants.team}/$id');
      await fetchMembers();
      _showSuccess('done'.tr);
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  void _showError(dynamic e) {
    Get.snackbar('error'.tr, e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('success'.tr, msg, snackPosition: SnackPosition.BOTTOM);
  }
}
