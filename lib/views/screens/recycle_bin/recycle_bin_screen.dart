import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/recycle_bin_controller.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late final RecycleBinController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(RecycleBinController());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'recycle_bin'.tr,
          showBack: true,
          actions: [
            if (canMutate)
              IconButton(
                icon: const Icon(Icons.delete_forever_outlined),
                tooltip: 'empty_recycle_bin'.tr,
                onPressed: () => _confirmEmpty(),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'cases'.tr),
              Tab(text: 'minutes'.tr),
              Tab(text: 'sessions'.tr),
              Tab(text: 'tasks'.tr),
              Tab(text: 'files'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (ctrl.isLoading.value) return const LoadingWidget();
          return TabBarView(
            children: [
              _sectionList(
                items: ctrl.cases,
                type: 'cases',
                titleBuilder: (e) =>
                    e['case_number']?.toString() ??
                    e['subject']?.toString() ??
                    '#${e['id']}',
                subtitleBuilder: (e) =>
                    e['client'] is Map ? (e['client']['name']?.toString() ?? '') : '',
                canMutate: canMutate,
              ),
              _sectionList(
                items: ctrl.minutes,
                type: 'minutes',
                titleBuilder: (e) =>
                    e['title']?.toString() ?? e['number']?.toString() ?? '#${e['id']}',
                subtitleBuilder: (e) => e['date']?.toString() ?? '',
                canMutate: canMutate,
              ),
              _sectionList(
                items: ctrl.sessions,
                type: 'sessions',
                titleBuilder: (e) {
                  final caseFile = e['case_file'];
                  final caseNum = caseFile is Map
                      ? caseFile['case_number']?.toString()
                      : null;
                  return caseNum != null
                      ? '${'session'.tr}: $caseNum'
                      : '${'session'.tr} #${e['id']}';
                },
                subtitleBuilder: (e) => e['date']?.toString() ?? '',
                canMutate: canMutate,
              ),
              _sectionList(
                items: ctrl.tasks,
                type: 'tasks',
                titleBuilder: (e) => e['title']?.toString() ?? '#${e['id']}',
                subtitleBuilder: (e) => e['due_date']?.toString() ?? '',
                canMutate: canMutate,
              ),
              _sectionList(
                items: ctrl.files,
                type: 'files',
                titleBuilder: (e) =>
                    e['file_name']?.toString() ??
                    e['original_name']?.toString() ??
                    '#${e['id']}',
                subtitleBuilder: (e) => e['file_type']?.toString() ?? '',
                canMutate: canMutate,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionList({
    required List<Map<String, dynamic>> items,
    required String type,
    required String Function(Map<String, dynamic>) titleBuilder,
    required String Function(Map<String, dynamic>) subtitleBuilder,
    required bool canMutate,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text('recycle_bin_empty_section'.tr,
            style: const TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: ctrl.fetchRecycleBin,
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.only(bottom: 24),
        itemBuilder: (_, i) {
          final item = items[i];
          final id = (item['id'] as num?)?.toInt();
          if (id == null) return const SizedBox.shrink();
          final deletedAt = item['deleted_at']?.toString();

          return Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.grey),
              title: Text(titleBuilder(item),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitleBuilder(item).isNotEmpty)
                    Text(subtitleBuilder(item)),
                  if (deletedAt != null)
                    Text(
                      '${'deleted_at'.tr}: ${AppHelpers.formatDateHuman(deletedAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
              isThreeLine: true,
              trailing: canMutate
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          tooltip: 'restore'.tr,
                          onPressed: () => ctrl.restore(type, id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          tooltip: 'delete_permanently'.tr,
                          onPressed: () => _confirmForceDelete(type, id),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _confirmForceDelete(String type, int id) {
    Get.dialog(AlertDialog(
      title: Text('delete_permanently'.tr),
      content: Text('delete_permanently_confirm'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.forceDelete(type, id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('delete'.tr),
        ),
      ],
    ));
  }

  void _confirmEmpty() {
    Get.dialog(AlertDialog(
      title: Text('empty_recycle_bin'.tr),
      content: Text('empty_recycle_bin_confirm'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.emptyBin();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('empty_recycle_bin'.tr),
        ),
      ],
    ));
  }
}
