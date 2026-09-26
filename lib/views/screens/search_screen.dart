import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as search;
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  late TabController _tabCtrl;

  static const _tabLabels = ['الكل', 'الموكلين', 'القضايا', 'الجلسات', 'المهام', 'الملفات'];
  static const _tabIcons = [Icons.apps, Icons.people, Icons.folder, Icons.gavel, Icons.task, Icons.attach_file];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  int _getCount(search.SearchController ctrl, int i) {
    switch (i) {
      case 0: return ctrl.totalResults;
      case 1: return ctrl.clientResults.length;
      case 2: return ctrl.caseResults.length;
      case 3: return ctrl.sessionResults.length;
      case 4: return ctrl.taskResults.length;
      case 5: return ctrl.fileResults.length;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<search.SearchController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _textCtrl,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث في كل شيء...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.black54),
            suffixIcon: Obx(() => ctrl.query.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black87),
                    onPressed: () {
                      _textCtrl.clear();
                      ctrl.search('');
                    },
                  )
                : const SizedBox.shrink()),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (q) => ctrl.search(q),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: List.generate(_tabLabels.length, (i) {
            return Tab(
              child: Obx(() {
                final count = _getCount(ctrl, i);
                final hasQuery = ctrl.query.value.isNotEmpty;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabIcons[i], size: 16),
                    const SizedBox(width: 4),
                    Text(_tabLabels[i], style: const TextStyle(fontSize: 13)),
                    if (hasQuery && count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ],
                  ],
                );
              }),
            );
          }),
        ),
      ),
      body: Obx(() {
        if (ctrl.query.value.isEmpty) {
          return _buildEmptyState();
        }
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!ctrl.hasResults) {
          return _buildNoResults(ctrl.query.value);
        }
        return TabBarView(
          controller: _tabCtrl,
          children: [
            _AllResultsTab(ctrl: ctrl),
            _ClientsTab(ctrl: ctrl),
            _CasesTab(ctrl: ctrl),
            _SessionsTab(ctrl: ctrl),
            _TasksTab(ctrl: ctrl),
            _FilesTab(ctrl: ctrl),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 16),
          const Text(
            'ابحث في الموكلين، القضايا،\nالجلسات، المهام والملفات',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String q) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج لـ "$q"',
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ TABS ═══════════════════════════

class _AllResultsTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _AllResultsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (ctrl.clientResults.isNotEmpty) ...[
          _SectionHeader('الموكلين', ctrl.clientResults.length, Colors.teal, Icons.people),
          ...ctrl.clientResults.map((c) => _ClientTile(c)),
          const Divider(height: 1),
        ],
        if (ctrl.caseResults.isNotEmpty) ...[
          _SectionHeader('القضايا', ctrl.caseResults.length, Colors.blue, Icons.folder),
          ...ctrl.caseResults.map((c) => _CaseTile(c)),
          const Divider(height: 1),
        ],
        if (ctrl.sessionResults.isNotEmpty) ...[
          _SectionHeader('الجلسات', ctrl.sessionResults.length, Colors.red, Icons.gavel),
          ...ctrl.sessionResults.map((s) => _SessionTile(s)),
          const Divider(height: 1),
        ],
        if (ctrl.taskResults.isNotEmpty) ...[
          _SectionHeader('المهام', ctrl.taskResults.length, Colors.purple, Icons.task),
          ...ctrl.taskResults.map((t) => _TaskTile(t)),
          const Divider(height: 1),
        ],
        if (ctrl.fileResults.isNotEmpty) ...[
          _SectionHeader('الملفات', ctrl.fileResults.length, Colors.blueGrey, Icons.attach_file),
          ...ctrl.fileResults.map((f) => _FileTile(f)),
        ],
      ],
    );
  }
}

class _ClientsTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _ClientsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.clientResults.isEmpty) return const _EmptyTab('الموكلين');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: ctrl.clientResults.map((c) => _ClientTile(c)).toList(),
    );
  }
}

class _CasesTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _CasesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.caseResults.isEmpty) return const _EmptyTab('القضايا');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: ctrl.caseResults.map((c) => _CaseTile(c)).toList(),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _SessionsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.sessionResults.isEmpty) return const _EmptyTab('الجلسات');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: ctrl.sessionResults.map((s) => _SessionTile(s)).toList(),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _TasksTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.taskResults.isEmpty) return const _EmptyTab('المهام');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: ctrl.taskResults.map((t) => _TaskTile(t)).toList(),
    );
  }
}

class _FilesTab extends StatelessWidget {
  final search.SearchController ctrl;
  const _FilesTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.fileResults.isEmpty) return const _EmptyTab('الملفات');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: ctrl.fileResults.map((f) => _FileTile(f)).toList(),
    );
  }
}

// ═══════════════════════════ TILES ═══════════════════════════

class _ClientTile extends StatelessWidget {
  final dynamic client;
  const _ClientTile(this.client);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.withOpacity(0.12),
        child: Text(
          client.name.isNotEmpty ? client.name[0] : '؟',
          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(client.phone ?? client.email ?? '—', style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Get.toNamed(AppRoutes.clientDetail, arguments: {'client': client}),
    );
  }
}

class _CaseTile extends StatelessWidget {
  final dynamic caseModel;
  const _CaseTile(this.caseModel);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(caseModel.status);
    final subtitle = [caseModel.caseType, caseModel.court, caseModel.clientName]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' | ');
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.folder, color: color, size: 20),
      ),
      title: Text(caseModel.caseNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'case': caseModel}),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final dynamic session;
  const _SessionTile(this.session);

  @override
  Widget build(BuildContext context) {
    final subtitle = [session.clientName, session.court, AppHelpers.formatDateTime(session.date)]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' | ');
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.gavel, color: Colors.red, size: 20),
      ),
      title: Text('جلسة: ${session.caseNumber ?? "بدون رقم"}', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'id': session.caseId}),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final dynamic task;
  const _TaskTile(this.task);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(task.status);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.task_outlined, color: color, size: 20),
      ),
      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(task.clientName ?? task.caseNumber ?? '—', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(task.status.tr, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
      onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': task}),
    );
  }
}

class _FileTile extends StatelessWidget {
  final dynamic file;
  const _FileTile(this.file);

  static IconData _icon(String? mime) {
    if (mime == null) return Icons.insert_drive_file;
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('word') || mime.contains('doc')) return Icons.description;
    if (mime.contains('sheet') || mime.contains('excel') || mime.contains('xls')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(_icon(file.mimeType), color: Colors.blueGrey, size: 20),
      ),
      title: Text(file.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(file.linkedEntityLabel ?? '—', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Get.toNamed(AppRoutes.fileViewer, arguments: {'file': file}),
    );
  }
}

// ═══════════════════════════ SHARED ═══════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  const _SectionHeader(this.title, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text('لا توجد نتائج في $label', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}



