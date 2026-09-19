import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/case_controller.dart';
import '../../controllers/minute_controller.dart';
import '../../controllers/task_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../widgets/custom_app_bar.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MinuteController>().fetchMinutes();
      Get.find<CaseController>().fetchArchivedSessions();
      Get.find<CaseController>().fetchArchivedCases();
      Get.find<TaskController>().fetchArchivedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final caseCtrl = Get.find<CaseController>();
    final minuteCtrl = Get.find<MinuteController>();
    final taskCtrl = Get.find<TaskController>();
    final auth = Get.find<AuthController>();
    final canMutate = auth.currentUser.value?.canMutateOfficeContent ?? true;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'archive'.tr,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'cases'.tr),
              Tab(text: 'tasks'.tr),
              Tab(text: 'minutes'.tr),
              Tab(text: 'sessions'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCasesList(caseCtrl, canMutate),
            _buildTasksList(taskCtrl, canMutate),
            _buildMinutesList(minuteCtrl, canMutate),
            _buildSessionsList(caseCtrl, canMutate),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesList(CaseController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.archivedCases;
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final c = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(c.caseNumber),
              subtitle: Text(c.subject ?? ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveCase(c.id),
                    )
                  : null,
              onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'case': c}),
            ),
          );
        },
      );
    });
  }

  Widget _buildTasksList(TaskController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.archivedTasks;
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final t = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(t.title),
              subtitle: Text(t.dueDate != null
                  ? AppHelpers.formatDateTime(t.dueDate)
                  : ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveTask(t.id),
                    )
                  : null,
              onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': t}),
            ),
          );
        },
      );
    });
  }

  Widget _buildMinutesList(MinuteController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.minutes.where((m) => m.isArchived).toList();
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final m = archived[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(m.title),
              subtitle: Text(m.minuteNumber ?? ''),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveMinute(m.id),
                    )
                  : null,
              onTap: () => canMutate
                  ? Get.toNamed(AppRoutes.minuteForm, arguments: {'minute': m})
                  : Get.toNamed(AppRoutes.minuteDetail, arguments: {'minute': m}),
            ),
          );
        },
      );
    });
  }

  Widget _buildSessionsList(CaseController ctrl, bool canMutate) {
    return Obx(() {
      final archived = ctrl.archivedSessions;
      if (archived.isEmpty) return _buildEmptyState();
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archived.length,
        itemBuilder: (_, i) {
          final s = archived[i];
          final caseLine = [
            if (s.caseNumber != null && s.caseNumber!.isNotEmpty) s.caseNumber,
            if (s.clientName != null && s.clientName!.isNotEmpty) s.clientName,
          ].whereType<String>().join(' - ');

          return Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.grey),
              title: Text(AppHelpers.formatDateTime(s.date)),
              subtitle: Text(caseLine.isNotEmpty ? caseLine : '---'),
              trailing: canMutate
                  ? IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      onPressed: () => ctrl.unarchiveSession(s.id, s.caseId),
                    )
                  : null,
              onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'id': s.caseId}),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('no_archived_items'.tr, style: const TextStyle(color: Colors.grey)),
    );
  }
}
