import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/client_model.dart';
import '../../data/models/case_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../data/models/file_model.dart';

class SearchController extends GetxController {
  final ApiService _api = ApiService();

  final query = ''.obs;
  final isLoading = false.obs;
  final clientResults = <ClientModel>[].obs;
  final caseResults = <CaseModel>[].obs;
  final taskResults = <TaskModel>[].obs;
  final sessionResults = <SessionModel>[].obs;
  final fileResults = <FileModel>[].obs;

  Future<void> search(String q) async {
    if (q.trim().isEmpty) {
      clientResults.clear();
      caseResults.clear();
      taskResults.clear();
      sessionResults.clear();
      fileResults.clear();
      query.value = '';
      return;
    }
    query.value = q;
    isLoading.value = true;
    try {
      await Future.wait([
        _searchClients(q),
        _searchCases(q),
        _searchTasks(q),
        _searchSessions(q),
        _searchFiles(q),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _searchClients(String q) async {
    try {
      final response = await _api.getList(
          '/clients/search/${Uri.encodeComponent(q)}');
      final list = _parseList(response);
      clientResults.value = list.map((e) => ClientModel.fromJson(e)).toList();
    } catch (_) {
      clientResults.clear();
    }
  }

  Future<void> _searchCases(String q) async {
    try {
      final response = await _api.getList('/cases/');
      final list = _parseList(response);
      final all = list.map((e) => CaseModel.fromJson(e)).toList();
      final qLower = q.toLowerCase();
      caseResults.value = all
          .where((c) =>
              c.caseNumber.toLowerCase().contains(qLower) ||
              (c.caseType?.toLowerCase().contains(qLower) ?? false) ||
              (c.court?.toLowerCase().contains(qLower) ?? false) ||
              (c.clientName?.toLowerCase().contains(qLower) ?? false) ||
              (c.subject?.toLowerCase().contains(qLower) ?? false) ||
              (c.opponent?.toLowerCase().contains(qLower) ?? false))
          .toList();
    } catch (_) {
      caseResults.clear();
    }
  }

  Future<void> _searchTasks(String q) async {
    try {
      final response = await _api.getList('/tasks/');
      final list = _parseList(response);
      final all = list.map((e) => TaskModel.fromJson(e)).toList();
      final qLower = q.toLowerCase();
      taskResults.value = all
          .where((t) =>
              t.title.toLowerCase().contains(qLower) ||
              (t.description?.toLowerCase().contains(qLower) ?? false) ||
              (t.caseNumber?.toLowerCase().contains(qLower) ?? false) ||
              (t.clientName?.toLowerCase().contains(qLower) ?? false))
          .toList();
    } catch (_) {
      taskResults.clear();
    }
  }

  Future<void> _searchSessions(String q) async {
    try {
      final response = await _api.getList('/cases/all-sessions');
      final list = _parseList(response);
      final all = list.map((e) => SessionModel.fromJson(e)).toList();
      final qLower = q.toLowerCase();
      sessionResults.value = all
          .where((s) =>
              (s.caseNumber?.toLowerCase().contains(qLower) ?? false) ||
              (s.court?.toLowerCase().contains(qLower) ?? false) ||
              (s.clientName?.toLowerCase().contains(qLower) ?? false) ||
              s.decisions.toLowerCase().contains(qLower) ||
              (s.notes?.toLowerCase().contains(qLower) ?? false))
          .toList();
    } catch (_) {
      sessionResults.clear();
    }
  }

  Future<void> _searchFiles(String q) async {
    try {
      final response = await _api.getList('/files/');
      final list = _parseList(response);
      final all = list.map((e) => FileModel.fromJson(e)).toList();
      final qLower = q.toLowerCase();
      fileResults.value = all
          .where((f) =>
              (f.originalName?.toLowerCase().contains(qLower) ?? false) ||
              (f.fileName?.toLowerCase().contains(qLower) ?? false) ||
              (f.caseNumber?.toLowerCase().contains(qLower) ?? false) ||
              (f.clientName?.toLowerCase().contains(qLower) ?? false) ||
              (f.taskTitle?.toLowerCase().contains(qLower) ?? false))
          .toList();
    } catch (_) {
      fileResults.clear();
    }
  }

  List<dynamic> _parseList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      return response['data'] as List? ?? [];
    }
    return [];
  }

  bool get hasResults =>
      clientResults.isNotEmpty ||
      caseResults.isNotEmpty ||
      taskResults.isNotEmpty ||
      sessionResults.isNotEmpty ||
      fileResults.isNotEmpty;

  int get totalResults =>
      clientResults.length +
      caseResults.length +
      taskResults.length +
      sessionResults.length +
      fileResults.length;
}
