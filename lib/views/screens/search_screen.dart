import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as search;
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<search.SearchController>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search... / بحث...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (q) => ctrl.search(q),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.text.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 80, color: Colors.grey),
                SizedBox(height: 12),
                Text('Search clients, cases, tasks\nابحث في الموكلين، القضايا، المهام',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        if (!ctrl.hasResults) {
          return Center(
            child: Text(
              'No results for "${_ctrl.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView(
          children: [
            if (ctrl.clientResults.isNotEmpty) ...[
              _SectionHeader(
                  'Clients / الموكلين', ctrl.clientResults.length),
              ...ctrl.clientResults.map((c) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(c.name[0], style: const TextStyle(color: AppTheme.primary)),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.phone ?? c.email ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Get.toNamed(AppRoutes.clientDetail,
                        arguments: {'client': c}),
                  )),
              const Divider(),
            ],
            if (ctrl.caseResults.isNotEmpty) ...[
              _SectionHeader('Cases / القضايا', ctrl.caseResults.length),
              ...ctrl.caseResults.map((c) => ListTile(
                    leading: Icon(Icons.folder_outlined,
                        color: AppTheme.getStatusColor(c.status)),
                    title: Text(c.caseNumber),
                    subtitle: Text('${c.caseType ?? ''} | ${c.court ?? ''}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Get.toNamed(AppRoutes.caseDetail,
                        arguments: {'case': c}),
                  )),
              const Divider(),
            ],
            if (ctrl.taskResults.isNotEmpty) ...[
              _SectionHeader('Tasks / المهام', ctrl.taskResults.length),
              ...ctrl.taskResults.map((t) => ListTile(
                    leading: Icon(Icons.task_outlined,
                        color: AppTheme.getStatusColor(t.status)),
                    title: Text(t.title),
                    subtitle: Text(t.status),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Get.toNamed(AppRoutes.taskDetail,
                        arguments: {'task': t}),
                  )),
            ],
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
