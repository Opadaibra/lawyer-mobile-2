import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/client_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  final _filtered = <dynamic>[].obs;
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClientController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;
      return Scaffold(
      appBar: CustomAppBar(
        title: 'clients'.tr,
        showBack: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searching = false);
                          _filtered.clear();
                        },
                      )
                    : null,
              ),
              onChanged: (q) async {
                if (q.trim().isEmpty) {
                  setState(() => _searching = false);
                  _filtered.clear();
                  return;
                }
                setState(() => _searching = true);
                final results = await ctrl.searchClients(q);
                _filtered.assignAll(results);
              },
            ),
          ),
          // List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) return const LoadingWidget();
              final items = _searching ? _filtered : ctrl.clients;
              if (items.isEmpty) {
                return EmptyStateWidget(
                  title: 'لا يوجد موكلون بعد',
                  icon: Icons.people_outline,
                  onAction: canMutate
                      ? () => Get.toNamed(AppRoutes.clientForm)
                      : null,
                  actionLabel: 'add_client'.tr,
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.fetchClients,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final client = items[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          child: Text(
                            client.name.isNotEmpty
                                ? client.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(client.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(client.phone ?? 'no_phone'.tr),
                              ],
                            ),
                            if (client.address != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      client.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        onTap: () => Get.toNamed(AppRoutes.clientDetail,
                            arguments: {'client': client}),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: canMutate
          ? FloatingActionButton.extended(
              heroTag: 'clients_fab',
              onPressed: () => Get.toNamed(AppRoutes.clientForm),
              icon: const Icon(Icons.add),
              label: Text('add_client'.tr),
            )
          : null,
    );
    });
  }

  void _confirmDelete(ClientController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Client / حذف الموكل'),
      content: const Text('Are you sure? / هل أنت متأكد؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel / إلغاء')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteClient(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete / حذف'),
        ),
      ],
    ));
  }
}
