import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'profile'.tr,
        showNotification: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      auth.userName.isNotEmpty
                          ? auth.userName[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    auth.userEmail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // User Menu Options
            _MenuTile(
              icon: Icons.people_outline,
              label: 'team'.tr,
              onTap: () => Get.toNamed(AppRoutes.team),
            ),
            
            _MenuTile(
              icon: Icons.business_outlined,
              label: 'office_info'.tr,
              onTap: () => Get.toNamed(AppRoutes.officeInfo),
            ),
            
            _MenuTile(
              icon: Icons.person_outline,
              label: 'profile'.tr,
              onTap: () {
                // Show profile info in a dialog or a simple page
                _showProfileInfo(context, auth);
              },
            ),
            
            _MenuTile(
              icon: Icons.lock_outline,
              label: 'change_password'.tr,
              onTap: () => _showChangePasswordDialog(context, auth),
            ),
            
            const Divider(height: 32),
            
            _MenuTile(
              icon: Icons.logout,
              label: 'logout'.tr,
              color: Colors.red,
              onTap: () => _confirmLogout(auth),
            ),

            const SizedBox(height: 32),
            const Text(
              'إدارة مكتب المحاماة v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileInfo(BuildContext context, AuthController auth) {
    Get.dialog(
      AlertDialog(
        title: Text('profile'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'name'.tr, value: auth.userName),
            const SizedBox(height: 8),
            _InfoRow(label: 'email'.tr, value: auth.userEmail),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('confirm'.tr)),
        ],
      ),
    );
  }

  void _confirmLogout(AuthController auth) {
    Get.dialog(AlertDialog(
      title: Text('logout'.tr),
      content: Text('سيتم تسجيل الخروج. انتبه: أي بيانات لم يتم مزامنتها مسبقاً قد يتم فقدانها.'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            auth.logout();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('logout'.tr),
        ),
      ],
    ));
  }

  void _showChangePasswordDialog(BuildContext context, AuthController auth) {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('change_password'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'current_password'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'new_password'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'confirm_password'.tr),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          Obx(() => ElevatedButton(
            onPressed: auth.isLoading.value ? null : () async {
              if (newPass.text != confirmPass.text) {
                Get.snackbar('error'.tr, 'passwords_dont_match'.tr);
                return;
              }
              final success = await auth.changePassword(
                currentPassword: currentPass.text,
                newPassword: newPass.text,
                confirmPassword: confirmPass.text,
              );
              if (success) {
                Get.back(); // إغلاق الديالوغ
                Get.snackbar('success'.tr, 'password_changed_success'.tr);
              }
            },
            child: auth.isLoading.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('save'.tr),
          )),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.primary),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
