import 'package:get/get.dart';
import '../data/services/api_service.dart';
import '../core/constants/app_constants.dart';

class OfficeModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? description;

  OfficeModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.description,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) => OfficeModel(
        id: json['id'] as int? ?? 0,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        address: json['address']?.toString(),
        description: json['description']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'description': description,
      };
}

class OfficeController extends GetxController {
  final ApiService _api = ApiService();

  final office = Rx<OfficeModel?>(null);
  final isLoading = false.obs;
  final isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOffice();
  }

  Future<void> fetchOffice() async {
    isLoading.value = true;
    try {
      final response = await _api.getList(AppConstants.offices);
      // السيرفر قد يعيد كائن مباشرة أو مصفوفة
      dynamic payload = response is Map ? (response['data'] ?? response) : response;
      if (payload is Iterable && payload.isNotEmpty) {
          payload = payload.first;
      }
      print('Fetch office extracted: $payload');

      if (payload != null && payload is Map) {
        office.value = OfficeModel.fromJson(Map<String, dynamic>.from(payload));
      }
    } catch (e) {
      print('Fetch office error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateOffice({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? description,
  }) async {
    isUpdating.value = true;
    try {
      final currentOfficeId = office.value?.id;
      if (currentOfficeId == null) {
          Get.snackbar('error'.tr, 'يرجى انتظار جلب بيانات المكتب أولاً');
          return false;
      }

      final response = await _api.patch('${AppConstants.offices}/$currentOfficeId', data: {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
      });

      dynamic payload = response is Map ? (response['data'] ?? response) : response;
      if (payload is Iterable && payload.isNotEmpty) {
          payload = payload.first;
      }

      // In offline mode, the API returns a simple success message, so we merge the updated data manually
      if (payload != null && payload is Map) {
        if (payload.containsKey('message') && payload['status'] == 'success' && !payload.containsKey('id')) {
           // Offline mock response
           final updatedOffice = OfficeModel(
             id: currentOfficeId,
             name: name,
             phone: phone ?? office.value?.phone,
             address: address ?? office.value?.address,
           );
           office.value = updatedOffice;
        } else {
           office.value = OfficeModel.fromJson(Map<String, dynamic>.from(payload));
        }
      }
      Get.snackbar('success'.tr, 'تم تحديث البيانات بنجاح');
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
