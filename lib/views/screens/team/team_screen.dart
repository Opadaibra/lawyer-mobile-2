import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/team_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TeamController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'فريق العمل',
        showNotification: false,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.members.isEmpty) {
          return const Center(child: Text('لا يوجد أعضاء في الفريق حالياً'));
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.fetchMembers(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.members.length,
            itemBuilder: (context, index) {
              final member = ctrl.members[index];
              final String roleKey = (member['role']?.toString() ?? '').toLowerCase() + '_role';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  title: Text(member['name']?.toString() ?? 'بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${member['email']}\nالصفة: ${roleKey.tr}'),
                  trailing: (auth.currentUser.value?.id?.toString() != member['id']?.toString() &&
                       auth.currentUser.value?.role?.toUpperCase() == 'MANAGER')
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                final memberId = int.tryParse(member['id'].toString());
                                if (memberId == null) return;
                                if (value == 'edit') {
                                  _showEditMemberDialog(context, ctrl, member);
                                } else if (value == 'password') {
                                  _showChangePasswordDialog(context, ctrl, memberId);
                                } else if (value == 'delete') {
                                  _confirmRemove(ctrl, memberId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('تعديل')]),
                                ),
                                // تغيير كلمة المرور للمدير فقط
                                const PopupMenuItem(
                                  value: 'password',
                                  child: Row(children: [Icon(Icons.lock_reset, size: 20), SizedBox(width: 8), Text('تغيير كلمة المرور')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            )
                          : null,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final user = auth.currentUser.value;
        // فقط المدير يستطيع إضافة أعضاء
        if (user == null || user.role?.toUpperCase() != 'MANAGER') return const SizedBox();
        return FloatingActionButton(
          heroTag: 'team_fab',
          onPressed: () => _showAddMemberDialog(context, ctrl),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add),
        );
      }),
    );
  }

  void _showAddMemberDialog(BuildContext context, TeamController ctrl) {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final role = 'LAWYER'.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('إضافة عضو للفريق'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  hintText: 'الاسم الكامل',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                    value: role.value,
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: [
                      DropdownMenuItem(value: 'MANAGER', child: Text('manager_role'.tr)),
                      DropdownMenuItem(value: 'LAWYER', child: Text('lawyer_role'.tr)),
                      DropdownMenuItem(value: 'VIEWER', child: Text('مشاهد')),
                    ],
                    onChanged: (v) => role.value = v!,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (email.text.isNotEmpty && name.text.isNotEmpty && password.text.isNotEmpty) {
                Get.back();
                ctrl.addMember(
                  name: name.text.trim(),
                  email: email.text.trim(),
                  password: password.text.trim(),
                  role: role.value,
                );
              } else {
                Get.snackbar('خطأ', 'يرجى ملء جميع الحقول');
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, TeamController ctrl, Map<String, dynamic> member) {
    final memberId = int.tryParse(member['id'].toString());
    if (memberId == null) return;

    final name = TextEditingController(text: member['name']?.toString() ?? '');
    final email = TextEditingController(text: member['email']?.toString() ?? '');
    final role = (member['role']?.toString() ?? 'LAWYER').obs;

    Get.dialog(
      AlertDialog(
        title: const Text('تعديل معلومات العضو'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم', hintText: 'الاسم الكامل'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', hintText: 'user@example.com'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<String>(
                    value: role.value,
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: [
                      DropdownMenuItem(value: 'MANAGER', child: Text('manager_role'.tr)),
                      DropdownMenuItem(value: 'LAWYER', child: Text('lawyer_role'.tr)),
                      DropdownMenuItem(value: 'VIEWER', child: Text('مشاهد')),
                    ],
                    onChanged: (v) => role.value = v!,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (email.text.isNotEmpty && name.text.isNotEmpty) {
                Get.back();
                ctrl.updateMember(
                  id: memberId,
                  name: name.text.trim(),
                  email: email.text.trim(),
                  role: role.value,
                );
              } else {
                Get.snackbar('خطأ', 'يرجى ملء جميع الحقول');
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, TeamController ctrl, int memberId) {
    final password = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (password.text.length >= 6) {
                Get.back();
                ctrl.changeMemberPassword(memberId, password.text);
              } else {
                Get.snackbar('خطأ', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
              }
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(TeamController ctrl, dynamic id) {
    if (id == null) return;
    Get.dialog(
      AlertDialog(
        title: const Text('حذف عضو'),
        content: const Text('هل أنت متأكد من حذف هذا العضو من الفريق؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.removeMember(int.parse(id.toString()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
