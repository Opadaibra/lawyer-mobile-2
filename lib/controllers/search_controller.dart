import 'package:get/get.dart';
import '../../data/services/api_service.dart';
import '../../data/models/client_model.dart';
import '../../data/models/case_model.dart';
import '../../data/models/task_model.dart';

class SearchController extends GetxController {
  final ApiService _api = ApiService();

  final query = ''.obs;
  final isLoading = false.obs;
  final clientResults = <ClientModel>[].obs;
  final caseResults = <CaseModel>[].obs;
  final taskResults = <TaskModel>[].obs;

  Future<void> search(String q) async {
    if (q.trim().isEmpty) {
      clientResults.clear();
      caseResults.clear();
      taskResults.clear();
      return;
    }
    query.value = q;
    isLoading.value = true;
    try {
      await Future.wait([
        _searchClients(q),
        _searchCases(q),
        _searchTasks(q),
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
      caseResults.value = all
          .where((c) =>
              c.caseNumber.toLowerCase().contains(q.toLowerCase()) ||
              (c.caseType?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
              (c.court?.toLowerCase().contains(q.toLowerCase()) ?? false))
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
      taskResults.value = all
          .where((t) =>
              t.title.toLowerCase().contains(q.toLowerCase()) ||
              (t.description?.toLowerCase().contains(q.toLowerCase()) ?? false))
          .toList();
    } catch (_) {
      taskResults.clear();
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
      clientResults.isNotEmpty || caseResults.isNotEmpty || taskResults.isNotEmpty;
}
