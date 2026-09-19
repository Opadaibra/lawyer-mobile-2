import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/client_model.dart';
import '../../core/constants/app_constants.dart';
import 'dashboard_controller.dart';

class ClientController extends GetxController {
  final ApiService _api = ApiService();

  final clients = <ClientModel>[].obs;
  final selectedClient = Rx<ClientModel?>(null);
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  // ─── Fetch all clients ────────────────────────────────────────────────────
  Future<void> fetchClients() async {
    isLoading.value = true;
    try {
      final response = await _api.getList('${AppConstants.clients}/');
      final list = _parseList(response);
      final clientList = list.map((e) => ClientModel.fromJson(e)).toList();
      // ترتيب أبجدي (أ ← ي)
      clientList.sort((a, b) => a.name.compareTo(b.name));
      clients.value = clientList;
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Get client by ID ─────────────────────────────────────────────────────
  Future<void> fetchClientById(int id) async {
    isLoading.value = true;
    try {
      final response = await _api.get('${AppConstants.clients}/$id');
      final data = _extractData(response);
      selectedClient.value = ClientModel.fromJson(data);
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Search clients ───────────────────────────────────────────────────────
  Future<List<ClientModel>> searchClients(String query) async {
    if (query.trim().isEmpty) return clients;
    try {
      final response = await _api.getList(
          '${AppConstants.clients}/search/${Uri.encodeComponent(query)}');
      final list = _parseList(response);
      return list.map((e) => ClientModel.fromJson(e)).toList();
    } catch (_) {
      return clients
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              (c.phone?.contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
  }

  // ─── Create client ────────────────────────────────────────────────────────
  Future<int?> createClient(ClientModel client) async {
    isSubmitting.value = true;
    try {
      final response = await _api.post(AppConstants.clients, data: client.toCreateJson());
      final data = _extractData(response);
      final newClient = ClientModel.fromJson(data);
      await fetchClients();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('Client added successfully / تم إضافة الموكل');
      return newClient.id;
    } catch (e) {
      _showError(e);
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Update client ────────────────────────────────────────────────────────
  Future<bool> updateClient(int id, ClientModel client) async {
    isSubmitting.value = true;
    try {
      await _api.patch('${AppConstants.clients}/$id', data: client.toCreateJson());
      await fetchClients();
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      Get.back();
      _showSuccess('Client updated successfully / تم تحديث الموكل');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Delete client ────────────────────────────────────────────────────────
  Future<bool> deleteClient(int id) async {
    try {
      await _api.delete('${AppConstants.clients}/$id');
      clients.removeWhere((c) => c.id == id);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      _showSuccess('Client deleted / تم حذف الموكل');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  // ─── Star Toggle ──────────────────────────────────────────────────────────
  Future<void> toggleStar(int id) async {
    try {
      await _api.post('${AppConstants.clients}/$id/star');
      await fetchClients();
      if (selectedClient.value?.id == id) {
        await fetchClientById(id);
      }
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Link File ────────────────────────────────────────────────────────────
  Future<void> linkFile(int clientId, int fileId) async {
    try {
      await _api.post('${AppConstants.clients}/$clientId/link-file',
          data: {'file_id': fileId});
      _showSuccess('File linked successfully / تم ربط الملف');
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Profile Picture Upload ───────────────────────────────────────────────
  Future<bool> uploadProfilePicture(int clientId, String filePath) async {
    try {
      await _api.uploadFile(
        filePath: filePath,
        fileName: 'profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        customEndpoint: '/clients/$clientId/upload-profile-picture/',
      );
      _showSuccess('Profile picture updated / تم تحديث صورة الموكل');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  // ─── Change Password ──────────────────────────────────────────────────────
  Future<bool> changePassword(int clientId, String password, String confirmation) async {
    isSubmitting.value = true;
    try {
      await _api.put('/clients/$clientId/change-password', data: {
        'password': password,
        'password_confirmation': confirmation,
      });
      Get.back();
      _showSuccess('تم إعادة تعيين كلمة المرور بنجاح');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? response['clients'] as List? ?? [];
    }
    return [];
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }

  void _showError(dynamic e) {
    Get.snackbar('Error / خطأ', e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success / نجاح', msg, snackPosition: SnackPosition.BOTTOM);
  }
}
