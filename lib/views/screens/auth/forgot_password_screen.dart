import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/forgot_password_controller.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ForgotPasswordController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              if (ctrl.step.value == ForgotPasswordStep.email) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset,
                        size: 80, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أدخل بريدك الإلكتروني المسجل لدينا وسنرسل لك رمز التحقق (OTP) لتغيير كلمة المرور.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: ctrl.emailController,
                      decoration: InputDecoration(
                        labelText: 'email'.tr,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    ctrl.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  ctrl.sendOtp(ctrl.emailController.text),
                              child: const Text('إرسال الرمز'),
                            ),
                          ),
                  ],
                );
              } else if (ctrl.step.value == ForgotPasswordStep.otp) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        size: 80, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    const Text(
                      'رمز التحقق',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لقد أرسلنا رمزاً مكوناً من 6 أرقام إلى بريدك\n${ctrl.savedEmail}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: ctrl.otpController,
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق (OTP)',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 24),
                    ctrl.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  ctrl.verifyOtp(ctrl.otpController.text),
                              child: const Text('تحقق من الرمز'),
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ctrl.step.value = ForgotPasswordStep.email;
                      },
                      child: const Text('تغيير البريد الإلكتروني'),
                    )
                  ],
                );
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.password, size: 80, color: AppTheme.primary),
                    const SizedBox(height: 24),
                    const Text(
                      'كلمة مرور جديدة',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: ctrl.passwordController,
                      decoration: InputDecoration(
                        labelText: 'new_password'.tr,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ctrl.confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'confirm_password'.tr,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ctrl.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => ctrl.resetPassword(
                                ctrl.passwordController.text,
                                ctrl.confirmPasswordController.text,
                              ),
                              child: const Text('حفظ وتغيير'),
                            ),
                          ),
                  ],
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
