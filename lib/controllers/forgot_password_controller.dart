import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/api_service.dart';

enum ForgotPasswordStep { email, otp, newPassword }

class ForgotPasswordController extends GetxController {
  final ApiService _api = ApiService();

  final step = ForgotPasswordStep.email.obs;
  final isLoading = false.obs;

  String savedEmail = '';
  String savedOtp = '';

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> sendOtp(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showError('يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post('/forgot-password/send-otp', data: {'email': email});
      savedEmail = email;
      step.value = ForgotPasswordStep.otp;
      _showSuccess(response['message'] ?? 'تم إرسال رمز التحقق بنجاح');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.length != 6) {
      _showError('رمز التحقق يجب أن يتكون من 6 أرقام');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post('/forgot-password/verify-otp', data: {
        'email': savedEmail,
        'otp': otp,
      });
      savedOtp = otp;
      step.value = ForgotPasswordStep.newPassword;
      _showSuccess(response['message'] ?? 'تم التحقق من الرمز بنجاح');
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String password, String confirmPassword) async {
    if (password.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (password != confirmPassword) {
      _showError('كلمتا المرور غير متطابقتين');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post('/forgot-password/reset', data: {
        'email': savedEmail,
        'otp': savedOtp,
        'password': password,
      });
      FocusManager.instance.primaryFocus?.unfocus();
      _showSuccess(response['message'] ?? 'تم تغيير كلمة المرور بنجاح');
      Get.offAllNamed('/login'); // العودة لشاشة تسجيل الدخول
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
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
