import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/client_controller.dart';
import '../../../data/models/client_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  ClientModel? clientData;

  @override
  void initState() {
    super.initState();
    final clientCtrl = Get.find<ClientController>();
    if (Get.arguments?['client'] is ClientModel) {
      clientData = Get.arguments['client'] as ClientModel;
    } else if (Get.arguments?['id'] != null) {
      final id = Get.arguments['id'] is int ? Get.arguments['id'] : int.tryParse(Get.arguments['id'].toString());
      clientData = clientCtrl.clients.firstWhereOrNull((c) => c.id == id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (clientData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: const Center(child: Text('Client not found or loading...\nالموكل غير موجود أو قيد التحميل')),
      );
    }
    final client = clientData!;
    final clientCtrl = Get.find<ClientController>();
    final auth = Get.find<AuthController>();
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: client.name,
        actions: [
          if (canMutate)
            IconButton(
              icon: const Icon(Icons.star_outline),
              onPressed: () => clientCtrl.toggleStar(client.id),
            ),
          if (canMutate)
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                _showLinkFileDialog(context, clientCtrl, client.id);
              },
            ),
          if (canMutate)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  Get.toNamed(AppRoutes.clientForm, arguments: {'client': client}),
            ),
          if (canMutate)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, clientCtrl, client.id),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (client.email != null)
                            _InfoRow(Icons.email_outlined, client.email!),
                          if (client.phone != null)
                            _InfoRow(Icons.phone_outlined, client.phone!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('details'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Divider(),
                    if (client.powerOfAttorneyNumber != null)
                      _DetailRow('power_of_attorney_number'.tr, client.powerOfAttorneyNumber!,
                          Icons.gavel_outlined),
                    if (client.address != null && client.address!.isNotEmpty)
                      _DetailRow('address'.tr, client.address!,
                          Icons.location_on_outlined),
                    if (client.notes != null && client.notes!.isNotEmpty)
                      _DetailRow('notes'.tr, client.notes!,
                          Icons.notes_outlined),
                    _DetailRow(
                      'member_since'.tr,
                      AppHelpers.formatDateHuman(client.createdAt),
                      Icons.calendar_today_outlined,
                    ),
                    if (canMutate) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showChangePasswordDialog(context, clientCtrl, client.id),
                          icon: const Icon(Icons.lock_reset, color: AppTheme.primary),
                          label: const Text('إعادة تعيين كلمة المرور', style: TextStyle(color: AppTheme.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.cases, arguments: {'clientId': client.id}), 
                icon: const Icon(Icons.folder_outlined),
                label: Text('cases'.tr),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.minutes, arguments: {'clientId': client.id}),
                icon: const Icon(Icons.article_outlined),
                label: Text('minutes'.tr),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ClientController ctrl, int clientId) {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          Obx(() => ElevatedButton(
                onPressed: ctrl.isSubmitting.value
                    ? null
                    : () async {
                        if (passwordCtrl.text.length < 6) {
                          Get.snackbar('خطأ', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                          return;
                        }
                        if (passwordCtrl.text != confirmCtrl.text) {
                          Get.snackbar('خطأ', 'كلمتا المرور غير متطابقتين');
                          return;
                        }
                        final success = await ctrl.changePassword(
                          clientId,
                          passwordCtrl.text,
                          confirmCtrl.text,
                        );
                        if (success) Get.back();
                      },
                child: ctrl.isSubmitting.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('تغيير'),
              )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClientController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete_client'.tr),
      content: Text('are_you_sure'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteClient(id).then((success) {
              if (success) Get.back();
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }

  void _showLinkFileDialog(BuildContext context, ClientController ctrl, int clientId) {
    Get.snackbar('Feature', 'File picker to be implemented');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
