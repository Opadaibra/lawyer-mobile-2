import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../services/storage_service.dart';
import '../../controllers/auth_controller.dart';
import 'offline_sync_service.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final token = StorageService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
      if (token != null && token != 'offline') 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'message': 'فشل في قراءة بيانات الخادم',
        'status_code': response.statusCode
      };
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode == 401) {
      throw const SocketException('دخول غير مصرح به (تم التحويل تلقائياً لوضع عدم الاتصال)');
    }
    // 5xx: سيتم معالجتها في catch block وإضافتها للقائمة صامتاً
    if (response.statusCode >= 500) {
      throw const SocketException('خطأ خادم');
    }
    if (response.statusCode >= 400) {
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body);
      } catch (_) {}

      String message = 'حدث خطأ في الخادم (${response.statusCode})';

      if (body.containsKey('errors') && body['errors'] != null) {
        if (body['errors'] is Map) {
          final errMap = body['errors'] as Map;
          message = errMap.values.expand((e) => e is List ? e : [e]).join('\n');
          if (message.contains('The email has already been taken')) {
              message = 'هذا البريد الإلكتروني مسجل مسبقاً';
          }
          if (message.contains('The password must be at least')) {
              message = 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
          }
        } else {
          message = body['errors'].toString();
        }
      } else if (body['message'] != null) {
        message = body['message'].toString();
        if (message == 'Invalid email or password') {
            message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        }
        if (message == 'Current password is incorrect') {
            message = 'كلمة المرور الحالية غير صحيحة';
        }
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }

      if (message.toLowerCase().contains('unauthenticated') ||
          message.toLowerCase().contains('token expired') ||
          message.contains('انتهت صلاحية الجلسة')) {
        throw SocketException(message);
      }

      throw Exception(message);
    }
  }

  /// حذف عنصر من جميع الكاشات ذات الصلة — يُُُُُُُُُُُُُُُُُُُُُُستدعى بعد DELETE
  static void _removeItemFromListCaches(String endpoint) {
    final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return;
    final lastPart = parts.last;
    final id = int.tryParse(lastPart);
    if (id == null) return;
    final resource = parts.length >= 2 ? parts[parts.length - 2] : '';

    void removeFromCache(String key) {
      final cache = OfflineSyncService.getCachedResponse(key);
      if (cache == null) return;
      if (cache is List) {
        final updated = List.from(cache)..removeWhere((e) => e is Map && e['id'] == id);
        OfflineSyncService.cacheResponse(key, updated);
      } else if (cache is Map) {
        for (final listKey in ['data', resource, 'sessions', 'tasks', 'cases', 'clients', 'minutes', 'files']) {
          if (cache[listKey] is List) {
            (cache[listKey] as List).removeWhere((e) => e is Map && e['id'] == id);
          }
        }
        OfflineSyncService.cacheResponse(key, cache);
      }
    }

    // حذف من القائمة العامة (e.g. /sessions, /cases, /tasks)
    removeFromCache('/$resource');
    removeFromCache('/$resource/');
    // حذف من كاش all-sessions إن كان المورد جلسة
    if (resource == 'sessions') {
      removeFromCache('/cases/all-sessions');
    }
    // حذف من كاش القضية الخاص — نحتاج للعثور عن case_file_id في الكاشات المحتملة
    // نبحث في جميع كاشات /cases/*/sessions
    final allSessionsCache = OfflineSyncService.getCachedResponse('/cases/all-sessions');
    if (allSessionsCache is Map && allSessionsCache['data'] is List) {
      final list = allSessionsCache['data'] as List;
      final found = list.firstWhere((e) => e is Map && e['id'] == id, orElse: () => null);
      if (found != null) {
        final caseId = (found as Map)['case_file_id'];
        if (caseId != null) {
          removeFromCache('/cases/$caseId/sessions');
        }
      }
    }
  }

  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
    bool isRetry = false,
  }) async {
    try {
      final response = await requestFn();

      if (response.statusCode == 401 &&
          !isRetry &&
          endpoint != AppConstants.refresh &&
          endpoint != AppConstants.login) {
        // Skip refresh if token is offline
        if (StorageService.getToken() == 'offline') {
          throw Exception('لا يمكن اتمام العملية بهذه الصلاحيات (أوفلاين)');
        }

        final auth = Get.find<AuthController>();
        final success = await auth.refreshToken();

        if (success) {
          return await requestFn();
        } else {
          throw const SocketException(
              'تعذر الاتصال بالخادم، تم التحويل تلقائياً لوضع عدم الاتصال المؤقت');
        }
      }

      _handleError(response);
      return response;
    } on SocketException {
      throw const SocketException(
          'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة');
    } on HandshakeException {
      throw Exception('فشل الاتصال الآمن بالخادم');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    if (StorageService.isOfflineMode()) {
      final cached = OfflineSyncService.getCachedResponse(endpoint);
      if (cached != null) return cached;

      // Fallback for individual item fetch when created offline or not individually cached
      final parts = endpoint.split('/');
      if (parts.length >= 3 && parts.last.isNotEmpty) {
        final possibleId = int.tryParse(parts.last);
        if (possibleId != null) {
          final prefixIdx = endpoint.lastIndexOf('/');
          final listEndpoint = endpoint.substring(0, prefixIdx);
          final listCache = OfflineSyncService.getCachedResponse(listEndpoint);
          if (listCache != null) {
            List<dynamic> items = [];
            if (listCache is List) {
              items = listCache;
            } else if (listCache is Map) {
              // Try to find a list in common keys
              for (var key in ['data', parts[1]]) {
                if (listCache[key] is List) {
                  items = listCache[key];
                  break;
                }
              }
            }

            try {
              final item = items.firstWhere((e) => e is Map && e['id'] == possibleId,
                  orElse: () => null);
              if (item != null) {
                // Wrap it in a 'data' envelope to mimic standard individual payload
                return {'data': Map<String, dynamic>.from(item)};
              }
            } catch (_) {}
          }
        }
      }
      return {};
    }
    try {
      final response = await _requestWithRetry(
        () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      final json = _parseResponse(response);
      OfflineSyncService.cacheResponse(endpoint, json);
      return json;
    } catch (e) {
      if (e is SocketException || e.toString().contains('الإنترنت')) {
        final cached = OfflineSyncService.getCachedResponse(endpoint);
        if (cached != null) return cached;
        return {};
      }
      rethrow;
    }
  }

  Future<dynamic> getList(String endpoint) async {
    if (StorageService.isOfflineMode()) {
      final cached = OfflineSyncService.getCachedResponse(endpoint);
      if (cached != null) return cached;
      return [];
    }
    try {
      final response = await _requestWithRetry(
        () => http.get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      final json = jsonDecode(response.body);
      OfflineSyncService.cacheResponse(endpoint, json);
      return json;
    } catch (e) {
      if (e is SocketException || e.toString().contains('الإنترنت')) {
        final cached = OfflineSyncService.getCachedResponse(endpoint);
        if (cached != null) return cached;
        return [];
      }
      rethrow;
    }
  }

  static void _updateAllSessionsCacheForPostpone({
    required int sessionId,
    required String decisions,
    required Map<String, dynamic> newMock,
  }) {
    var archivedCache = OfflineSyncService.getCachedResponse('/cases/all-sessions?archived=true');
    List<dynamic>? archivedList;
    dynamic archivedRoot;
    if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
    else if (archivedCache is Map && archivedCache['data'] is List) {
      archivedList = archivedCache['data'] as List;
      archivedRoot = archivedCache;
    } else {
      archivedRoot = {"status": "success", "data": []};
      archivedList = archivedRoot['data'] as List;
    }

    var allCache = OfflineSyncService.getCachedResponse('/cases/all-sessions');
    if (allCache == null) {
      allCache = {"status": "success", "data": []};
    }
    List<dynamic>? list;
    dynamic root;
    if (allCache is List) {
      list = allCache;
      root = allCache;
    } else if (allCache is Map && allCache['data'] is List) {
      list = allCache['data'] as List;
      root = allCache;
    }
    if (list == null) return;
    final idx = list.indexWhere((e) => e is Map && e['id'] == sessionId);
    if (idx != -1) {
      final oldSess = Map<String, dynamic>.from(list[idx] as Map);
      oldSess['archived_at'] = DateTime.now().toIso8601String();
      if (decisions.isNotEmpty) {
        oldSess['decisions'] = decisions;
      }
      (list[idx] as Map)['archived_at'] = oldSess['archived_at'];
      if (decisions.isNotEmpty) {
        (list[idx] as Map)['decisions'] = decisions;
      }

      if (archivedList != null && archivedList.indexWhere((x) => x['id'] == sessionId) == -1) {
        archivedList.add(oldSess);
      }
    }
    list.add(newMock);
    OfflineSyncService.cacheResponse('/cases/all-sessions', root);
    OfflineSyncService.cacheResponse('/cases/all-sessions?archived=true', archivedRoot);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    if (StorageService.isOfflineMode() && !isSyncCall) {
      final tempId = OfflineSyncService.generateTempId();
      await OfflineSyncService.queueAction(
          method: 'POST', endpoint: endpoint, data: data, tempId: tempId);
      final mockItem = {'id': tempId, ...?data};

      await OfflineSyncService.appendToCacheList(endpoint, mockItem);
      ApiService._handleOfflineArchiveOrUnarchive(endpoint);

      if (data != null) {
        if (endpoint.contains(AppConstants.minutes)) {
          final caseId = data['case_file_id'] ?? data['case_id'];
          if (caseId != null) {
            await OfflineSyncService.appendToCacheList(
                '/cases/$caseId/minutes', mockItem);
          }
        }
        if (endpoint.contains(AppConstants.tasks)) {
          final caseId = data['case_file_id'] ?? data['case_id'];
          if (caseId != null) {
            await OfflineSyncService.appendToCacheList(
                '/tasks/by-case/$caseId', mockItem);
          }
        }
        if (endpoint.contains('/sessions') && !endpoint.contains('/postpone')) {
          final caseId = data['case_file_id'] ?? data['case_id'];
          if (caseId != null) {
             final listCache = OfflineSyncService.getCachedResponse('/cases/$caseId/sessions');
             if (listCache is Map && listCache['data'] is List) {
                 final list = listCache['data'] as List;
                 for (var e in list) {
                     if (e is Map && e['archived_at'] == null) {
                         e['archived_at'] = DateTime.now().toIso8601String();
                     }
                 }
                 OfflineSyncService.cacheResponse('/cases/$caseId/sessions', listCache);
             }
             if (!endpoint.contains('/cases/$caseId/sessions')) {
                 await OfflineSyncService.appendToCacheList('/cases/$caseId/sessions', mockItem);
             }

             var archivedCache = OfflineSyncService.getCachedResponse('/cases/all-sessions?archived=true');
             List<dynamic>? archivedList;
             dynamic archivedRoot;
             if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
             else if (archivedCache is Map && archivedCache['data'] is List) {
               archivedList = archivedCache['data'] as List;
               archivedRoot = archivedCache;
             } else {
               archivedRoot = {"status": "success", "data": []};
               archivedList = archivedRoot['data'] as List;
             }

             var allCache = OfflineSyncService.getCachedResponse('/cases/all-sessions');
             if (allCache == null) {
               allCache = {"status": "success", "data": []};
             }
             List<dynamic>? allList;
             dynamic allRoot;
             if (allCache is List) { allList = allCache; allRoot = allCache; }
             else if (allCache is Map && allCache['data'] is List) {
               allList = allCache['data'] as List;
               allRoot = allCache;
             }
             
             if (allList != null) {
               for (var e in allList) {
                 if (e is Map && (e['case_file_id'] == caseId || e['case_id'] == caseId) && e['archived_at'] == null) {
                   final archivedItem = Map<String, dynamic>.from(e);
                   archivedItem['archived_at'] = DateTime.now().toIso8601String();
                   e['archived_at'] = archivedItem['archived_at'];
                   
                   if (archivedList != null && archivedList.indexWhere((x) => x['id'] == e['id']) == -1) {
                     archivedList.add(archivedItem);
                   }
                 }
               }
               allList.add(mockItem);
               OfflineSyncService.cacheResponse('/cases/all-sessions', allRoot);
               OfflineSyncService.cacheResponse('/cases/all-sessions?archived=true', archivedRoot);
             }
          }
        }
        if (endpoint.contains('/postpone')) {
          final caseId = data['case_id'];
          if (caseId != null) {
             final listCache = OfflineSyncService.getCachedResponse('/cases/$caseId/sessions');
             if (listCache is Map && listCache['data'] is List) {
                final list = listCache['data'] as List;
                final parts = endpoint.split('/');
                int? sessionId;
                if (parts.length >= 3) {
                   sessionId = int.tryParse(parts[2]);
                   final idx = list.indexWhere((e) => e is Map && e['id'] == sessionId);
                   if (idx != -1) {
                      list[idx]['archived_at'] = DateTime.now().toIso8601String();
                      list[idx]['decisions'] = data['decisions'] ?? list[idx]['decisions'];
                   }
                }
                final newMock = {
                   'id': tempId,
                   'date': data['new_date'],
                   'decisions': '',
                   'notes': '',
                   'case_file_id': caseId,
                   'created_at': DateTime.now().toIso8601String(),
                };
                list.add(newMock);
                OfflineSyncService.cacheResponse('/cases/$caseId/sessions', listCache);
                if (sessionId != null) {
                  ApiService._updateAllSessionsCacheForPostpone(
                    sessionId: sessionId,
                    decisions: data['decisions']?.toString() ?? '',
                    newMock: newMock,
                  );
                }
             }
          }
        }
      }

      return {
        'message': 'تم الحفظ محلياً',
        'id': tempId,
        'data': mockItem,
        'status': 'success'
      };
    }

    try {
      final response = await _requestWithRetry(
        () => http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: data != null ? jsonEncode(data) : null,
        ),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          !endpoint.contains(AppConstants.login) &&
          !endpoint.contains(AppConstants.register) &&
          !endpoint.contains(AppConstants.changePassword) &&
          !endpoint.contains(AppConstants.refresh)) {
        final tempId = OfflineSyncService.generateTempId();
        await OfflineSyncService.queueAction(
            method: 'POST', endpoint: endpoint, data: data, tempId: tempId);
        final mockItem = {'id': tempId, ...?data};

        await OfflineSyncService.appendToCacheList(endpoint, mockItem);
        ApiService._handleOfflineArchiveOrUnarchive(endpoint);

        // Update related lists
        if (data != null) {
          if (endpoint.contains(AppConstants.minutes)) {
            final caseId = data['case_file_id'] ?? data['case_id'];
            if (caseId != null) {
              await OfflineSyncService.appendToCacheList(
                  '/cases/$caseId/minutes', mockItem);
            }
          }
          if (endpoint.contains(AppConstants.tasks)) {
            final caseId = data['case_file_id'] ?? data['case_id'];
            if (caseId != null) {
              await OfflineSyncService.appendToCacheList(
                  '/tasks/by-case/$caseId', mockItem);
            }
          }
          if (endpoint.contains('/sessions') && !endpoint.contains('/postpone')) {
            final caseId = data['case_file_id'] ?? data['case_id'];
            if (caseId != null) {
               final listCache = OfflineSyncService.getCachedResponse('/cases/$caseId/sessions');
               if (listCache is Map && listCache['data'] is List) {
                   final list = listCache['data'] as List;
                   for (var e in list) {
                       if (e is Map && e['archived_at'] == null) {
                           e['archived_at'] = DateTime.now().toIso8601String();
                       }
                   }
                   OfflineSyncService.cacheResponse('/cases/$caseId/sessions', listCache);
               }
               if (!endpoint.contains('/cases/$caseId/sessions')) {
                   await OfflineSyncService.appendToCacheList('/cases/$caseId/sessions', mockItem);
               }

               var archivedCache = OfflineSyncService.getCachedResponse('/cases/all-sessions?archived=true');
               List<dynamic>? archivedList;
               dynamic archivedRoot;
               if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
               else if (archivedCache is Map && archivedCache['data'] is List) {
                 archivedList = archivedCache['data'] as List;
                 archivedRoot = archivedCache;
               } else {
                 archivedRoot = {"status": "success", "data": []};
                 archivedList = archivedRoot['data'] as List;
               }

               var allCache = OfflineSyncService.getCachedResponse('/cases/all-sessions');
               if (allCache == null) {
                 allCache = {"status": "success", "data": []};
               }
               List<dynamic>? allList;
               dynamic allRoot;
               if (allCache is List) { allList = allCache; allRoot = allCache; }
               else if (allCache is Map && allCache['data'] is List) {
                 allList = allCache['data'] as List;
                 allRoot = allCache;
               }
               
               if (allList != null) {
                 for (var e in allList) {
                   if (e is Map && (e['case_file_id'] == caseId || e['case_id'] == caseId) && e['archived_at'] == null) {
                     final archivedItem = Map<String, dynamic>.from(e);
                     archivedItem['archived_at'] = DateTime.now().toIso8601String();
                     e['archived_at'] = archivedItem['archived_at'];
                     
                     if (archivedList != null && archivedList.indexWhere((x) => x['id'] == e['id']) == -1) {
                       archivedList.add(archivedItem);
                     }
                   }
                 }
                 allList.add(mockItem);
                 OfflineSyncService.cacheResponse('/cases/all-sessions', allRoot);
                 OfflineSyncService.cacheResponse('/cases/all-sessions?archived=true', archivedRoot);
               }
            }
          }
          if (endpoint.contains('/postpone')) {
            final caseId = data['case_id'];
            if (caseId != null) {
               final listCache = OfflineSyncService.getCachedResponse('/cases/$caseId/sessions');
               if (listCache is Map && listCache['data'] is List) {
                  final list = listCache['data'] as List;
                  final parts = endpoint.split('/');
                  int? sessionId;
                  if (parts.length >= 3) {
                     sessionId = int.tryParse(parts[2]);
                     final idx = list.indexWhere((e) => e is Map && e['id'] == sessionId);
                     if (idx != -1) {
                        list[idx]['archived_at'] = DateTime.now().toIso8601String();
                        list[idx]['decisions'] = data['decisions'] ?? list[idx]['decisions'];
                     }
                  }
                  final newMock = {
                     'id': tempId,
                     'date': data['new_date'],
                     'decisions': '',
                     'notes': '',
                     'case_file_id': caseId,
                     'created_at': DateTime.now().toIso8601String(),
                  };
                  list.add(newMock);
                  OfflineSyncService.cacheResponse('/cases/$caseId/sessions', listCache);
                  // تحديث all-sessions أيضاً
                  if (sessionId != null) {
                    ApiService._updateAllSessionsCacheForPostpone(
                      sessionId: sessionId,
                      decisions: data['decisions']?.toString() ?? '',
                      newMock: newMock,
                    );
                  }
               }
            }
          }
        }

        return {
          'message': 'تم الحفظ محلياً',
          'id': tempId,
          'data': mockItem,
          'status': 'success'
        };
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    final Map<String, dynamic> requestData = data ?? {};
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'PATCH', endpoint: endpoint, data: requestData);
      await OfflineSyncService.updateCacheObject(endpoint, requestData);
      return {'message': 'تم التعديل محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () => http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(requestData),
        ),
        endpoint: endpoint,
      );
      print(response);

      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          !endpoint.contains(AppConstants.login) &&
          !endpoint.contains(AppConstants.register) &&
          !endpoint.contains(AppConstants.changePassword) &&
          !endpoint.contains(AppConstants.refresh)) {
        await OfflineSyncService.queueAction(
            method: 'PATCH', endpoint: endpoint, data: requestData);
        return {'message': 'تم التعديل محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isSyncCall = false,
  }) async {
    final Map<String, dynamic> requestData = data ?? {};
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'PUT', endpoint: endpoint, data: requestData);
      return {'message': 'تم التعديل محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () => http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(requestData),
        ),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          !endpoint.contains(AppConstants.login) &&
          !endpoint.contains(AppConstants.register) &&
          !endpoint.contains(AppConstants.changePassword) &&
          !endpoint.contains(AppConstants.refresh)) {
        await OfflineSyncService.queueAction(
            method: 'PUT', endpoint: endpoint, data: requestData);
        return {'message': 'تم التعديل محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint,
      {bool isSyncCall = false}) async {
    if (StorageService.isOfflineMode() && !isSyncCall) {
      await OfflineSyncService.queueAction(
          method: 'DELETE', endpoint: endpoint);
      _removeItemFromListCaches(endpoint);
      return {'message': 'تم الحذف محلياً', 'status': 'success'};
    }

    try {
      final response = await _requestWithRetry(
        () =>
            http.delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders()),
        endpoint: endpoint,
      );
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          !endpoint.contains(AppConstants.login) &&
          !endpoint.contains(AppConstants.register) &&
          !endpoint.contains(AppConstants.changePassword) &&
          !endpoint.contains(AppConstants.refresh)) {
        await OfflineSyncService.queueAction(
            method: 'DELETE', endpoint: endpoint);
        _removeItemFromListCaches(endpoint);
        return {'message': 'تم الحذف محلياً', 'status': 'success'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    String? customEndpoint,
    Map<String, String>? fields,
    bool isSyncCall = false,
  }) async {
    final endpoint = customEndpoint ?? AppConstants.filesUpload;

    if (StorageService.isOfflineMode() && !isSyncCall) {
      final tempId = OfflineSyncService.generateTempId();
      await OfflineSyncService.queueAction(
        method: 'UPLOAD',
        endpoint: endpoint,
        localFilePath: filePath,
        fileName: fileName,
        fileCustomEndpoint: endpoint,
        fields: fields,
        tempId: tempId,
      );

      final mockItem = {
        'id': tempId,
        'original_name': fileName,
        'file_name': fileName,
        'created_at': DateTime.now().toIso8601String(),
        'local_path': filePath,
        ...?fields,
      };

      await OfflineSyncService.appendToCacheList(AppConstants.files, mockItem);
      if (fields != null) {
        if (fields.containsKey('case_id')) {
          await OfflineSyncService.appendToCacheList(
              '/files/by-case/${fields['case_id']}', mockItem);
        }
        if (fields.containsKey('minute_id')) {
          await OfflineSyncService.appendToCacheList(
              '/files/by-minute/${fields['minute_id']}', mockItem);
        }
      }

      return {
        'message': 'تم حفظ الملف محلياً للمزامنة',
        'status': 'success',
        'data': mockItem
      };
    }

    Future<http.Response> doUpload() async {
      final token = StorageService.getToken();
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token != 'offline')
          'Authorization': 'Bearer $token',
      });
      request.files.add(await http.MultipartFile.fromPath('file', filePath,
          filename: fileName));
      if (fields != null) request.fields.addAll(fields);
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    try {
      final response = await _requestWithRetry(doUpload, endpoint: endpoint);
      return _parseResponse(response);
    } catch (e) {
      if (!isSyncCall &&
          !endpoint.contains(AppConstants.login) &&
          !endpoint.contains(AppConstants.register) &&
          !endpoint.contains(AppConstants.changePassword) &&
          !endpoint.contains(AppConstants.refresh)) {
        final tempId = OfflineSyncService.generateTempId();
        await OfflineSyncService.queueAction(
          method: 'UPLOAD',
          endpoint: endpoint,
          localFilePath: filePath,
          fileName: fileName,
          fileCustomEndpoint: endpoint,
          fields: fields,
          tempId: tempId,
        );

        final mockItem = {
          'id': tempId,
          'original_name': fileName,
          'file_name': fileName,
          'created_at': DateTime.now().toIso8601String(),
          ...?fields,
        };

        await OfflineSyncService.appendToCacheList(
            AppConstants.files, mockItem);
        if (fields != null) {
          if (fields.containsKey('case_id')) {
            await OfflineSyncService.appendToCacheList(
                '/files/by-case/${fields['case_id']}', mockItem);
          }
          if (fields.containsKey('minute_id')) {
            await OfflineSyncService.appendToCacheList(
                '/files/by-minute/${fields['minute_id']}', mockItem);
          }
        }

        return {
          'message': 'تم حفظ الملف محلياً للمزامنة',
          'status': 'success',
          'data': mockItem
        };
      }
      rethrow;
    }
  }

  static void _handleOfflineArchiveOrUnarchive(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final parts = cleanEndpoint.split('/');
    if (parts.length >= 3) {
      final type = parts[0];
      final idStr = parts[1];
      final action = parts[2];
      final id = int.tryParse(idStr);
      if (id != null && (action == 'archive' || action == 'unarchive')) {
        final isArchive = action == 'archive';
        if (type == 'cases') {
          _updateCaseArchiveCache(id, isArchive: isArchive);
        } else if (type == 'sessions') {
          _updateSessionArchiveCache(id, isArchive: isArchive);
        } else if (type == 'tasks') {
          _updateTaskArchiveCache(id, isArchive: isArchive);
        } else if (type == 'minutes') {
          _updateMinuteArchiveCache(id, isArchive: isArchive);
        }
      }
    }
  }

  static void _updateCaseArchiveCache(int id, {required bool isArchive}) {
    final activeCache = OfflineSyncService.getCachedResponse('/cases/');
    List<dynamic>? activeList;
    dynamic activeRoot;
    if (activeCache is List) { activeList = activeCache; activeRoot = activeCache; }
    else if (activeCache is Map && activeCache['data'] is List) {
      activeList = activeCache['data'] as List;
      activeRoot = activeCache;
    }
    
    Map<String, dynamic>? targetCase;
    if (activeList != null) {
      final idx = activeList.indexWhere((e) => e is Map && e['id'] == id);
      if (idx != -1) {
        targetCase = Map<String, dynamic>.from(activeList[idx] as Map);
        if (isArchive) {
          targetCase['archived_at'] = DateTime.now().toIso8601String();
          activeList.removeAt(idx);
        } else {
          targetCase['archived_at'] = null;
        }
        OfflineSyncService.cacheResponse('/cases/', activeRoot);
      }
    }

    final archivedCache = OfflineSyncService.getCachedResponse('/cases/?archived=true');
    List<dynamic>? archivedList;
    dynamic archivedRoot;
    if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
    else if (archivedCache is Map && archivedCache['data'] is List) {
      archivedList = archivedCache['data'] as List;
      archivedRoot = archivedCache;
    } else {
      archivedRoot = {"status": "success", "data": []};
      archivedList = archivedRoot['data'] as List;
    }

    if (archivedList != null) {
      final idx = archivedList.indexWhere((e) => e is Map && e['id'] == id);
      if (isArchive) {
        if (idx == -1 && targetCase != null) {
          archivedList.add(targetCase);
        }
      } else {
        if (idx != -1) {
          final caseObj = archivedList.removeAt(idx);
          if (caseObj is Map) {
            final parsedCase = Map<String, dynamic>.from(caseObj);
            parsedCase['archived_at'] = null;
            if (activeList != null && activeList.indexWhere((e) => e['id'] == id) == -1) {
              activeList.add(parsedCase);
              OfflineSyncService.cacheResponse('/cases/', activeRoot);
            }
          }
        }
      }
      OfflineSyncService.cacheResponse('/cases/?archived=true', archivedRoot);
    }
  }

  static void _updateSessionArchiveCache(int id, {required bool isArchive}) {
    final allCache = OfflineSyncService.getCachedResponse('/cases/all-sessions');
    List<dynamic>? allList;
    dynamic allRoot;
    if (allCache is List) { allList = allCache; allRoot = allCache; }
    else if (allCache is Map && allCache['data'] is List) {
      allList = allCache['data'] as List;
      allRoot = allCache;
    }

    Map<String, dynamic>? targetSession;
    int? caseId;
    if (allList != null) {
      final idx = allList.indexWhere((e) => e is Map && e['id'] == id);
      if (idx != -1) {
        targetSession = Map<String, dynamic>.from(allList[idx] as Map);
        caseId = targetSession['case_file_id'] ?? targetSession['case_id'];
        if (isArchive) {
          targetSession['archived_at'] = DateTime.now().toIso8601String();
          allList.removeAt(idx);
        } else {
          targetSession['archived_at'] = null;
        }
        OfflineSyncService.cacheResponse('/cases/all-sessions', allRoot);
      }
    }

    final archivedCache = OfflineSyncService.getCachedResponse('/cases/all-sessions?archived=true');
    List<dynamic>? archivedList;
    dynamic archivedRoot;
    if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
    else if (archivedCache is Map && archivedCache['data'] is List) {
      archivedList = archivedCache['data'] as List;
      archivedRoot = archivedCache;
    } else {
      archivedRoot = {"status": "success", "data": []};
      archivedList = archivedRoot['data'] as List;
    }

    if (archivedList != null) {
      final idx = archivedList.indexWhere((e) => e is Map && e['id'] == id);
      if (isArchive) {
        if (idx == -1 && targetSession != null) {
          archivedList.add(targetSession);
        }
      } else {
        if (idx != -1) {
          final sessObj = archivedList.removeAt(idx);
          if (sessObj is Map) {
            final parsedSess = Map<String, dynamic>.from(sessObj);
            parsedSess['archived_at'] = null;
            if (allList != null && allList.indexWhere((e) => e['id'] == id) == -1) {
              allList.add(parsedSess);
              OfflineSyncService.cacheResponse('/cases/all-sessions', allRoot);
            }
          }
        }
      }
      OfflineSyncService.cacheResponse('/cases/all-sessions?archived=true', archivedRoot);
    }

    if (caseId != null) {
      final caseSessCache = OfflineSyncService.getCachedResponse('/cases/$caseId/sessions');
      List<dynamic>? caseSessList;
      dynamic caseSessRoot;
      if (caseSessCache is List) { caseSessList = caseSessCache; caseSessRoot = caseSessCache; }
      else if (caseSessCache is Map && caseSessCache['data'] is List) {
        caseSessList = caseSessCache['data'] as List;
        caseSessRoot = caseSessCache;
      }
      if (caseSessList != null) {
        final idx = caseSessList.indexWhere((e) => e is Map && e['id'] == id);
        if (idx != -1) {
          if (isArchive) {
            caseSessList.removeAt(idx);
          } else {
            if (targetSession != null) {
              final parsed = Map<String, dynamic>.from(targetSession);
              parsed['archived_at'] = null;
              caseSessList.add(parsed);
            }
          }
          OfflineSyncService.cacheResponse('/cases/$caseId/sessions', caseSessRoot);
        }
      }
    }
  }

  static void _updateTaskArchiveCache(int id, {required bool isArchive}) {
    final activeCache = OfflineSyncService.getCachedResponse('/tasks/');
    List<dynamic>? activeList;
    dynamic activeRoot;
    if (activeCache is List) { activeList = activeCache; activeRoot = activeCache; }
    else if (activeCache is Map && activeCache['data'] is List) {
      activeList = activeCache['data'] as List;
      activeRoot = activeCache;
    }

    Map<String, dynamic>? targetTask;
    int? caseId;
    if (activeList != null) {
      final idx = activeList.indexWhere((e) => e is Map && e['id'] == id);
      if (idx != -1) {
        targetTask = Map<String, dynamic>.from(activeList[idx] as Map);
        caseId = targetTask['case_file_id'] ?? targetTask['case_id'];
        if (isArchive) {
          targetTask['archived_at'] = DateTime.now().toIso8601String();
          activeList.removeAt(idx);
        } else {
          targetTask['archived_at'] = null;
        }
        OfflineSyncService.cacheResponse('/tasks/', activeRoot);
      }
    }

    final archivedCache = OfflineSyncService.getCachedResponse('/tasks/?archived=true');
    List<dynamic>? archivedList;
    dynamic archivedRoot;
    if (archivedCache is List) { archivedList = archivedCache; archivedRoot = archivedCache; }
    else if (archivedCache is Map && archivedCache['data'] is List) {
      archivedList = archivedCache['data'] as List;
      archivedRoot = archivedCache;
    } else {
      archivedRoot = {"status": "success", "data": []};
      archivedList = archivedRoot['data'] as List;
    }

    if (archivedList != null) {
      final idx = archivedList.indexWhere((e) => e is Map && e['id'] == id);
      if (isArchive) {
        if (idx == -1 && targetTask != null) {
          archivedList.add(targetTask);
        }
      } else {
        if (idx != -1) {
          final taskObj = archivedList.removeAt(idx);
          if (taskObj is Map) {
            final parsedTask = Map<String, dynamic>.from(taskObj);
            parsedTask['archived_at'] = null;
            if (activeList != null && activeList.indexWhere((e) => e['id'] == id) == -1) {
              activeList.add(parsedTask);
              OfflineSyncService.cacheResponse('/tasks/', activeRoot);
            }
          }
        }
      }
      OfflineSyncService.cacheResponse('/tasks/?archived=true', archivedRoot);
    }

    if (caseId != null) {
      final caseTaskCache = OfflineSyncService.getCachedResponse('/tasks/by-case/$caseId');
      List<dynamic>? caseTaskList;
      dynamic caseTaskRoot;
      if (caseTaskCache is List) { caseTaskList = caseTaskCache; caseTaskRoot = caseTaskCache; }
      else if (caseTaskCache is Map && caseTaskCache['data'] is List) {
        caseTaskList = caseTaskCache['data'] as List;
        caseTaskRoot = caseTaskCache;
      }
      if (caseTaskList != null) {
        final idx = caseTaskList.indexWhere((e) => e is Map && e['id'] == id);
        if (idx != -1) {
          if (isArchive) {
            caseTaskList.removeAt(idx);
          } else {
            if (targetTask != null) {
              final parsed = Map<String, dynamic>.from(targetTask);
              parsed['archived_at'] = null;
              caseTaskList.add(parsed);
            }
          }
          OfflineSyncService.cacheResponse('/tasks/by-case/$caseId', caseTaskRoot);
        }
      }
    }
  }

  static void _updateMinuteArchiveCache(int id, {required bool isArchive}) {
    final activeCache = OfflineSyncService.getCachedResponse('/minutes/');
    List<dynamic>? activeList;
    dynamic activeRoot;
    if (activeCache is List) { activeList = activeCache; activeRoot = activeCache; }
    else if (activeCache is Map && activeCache['data'] is List) {
      activeList = activeCache['data'] as List;
      activeRoot = activeCache;
    }

    int? caseId;
    if (activeList != null) {
      final idx = activeList.indexWhere((e) => e is Map && e['id'] == id);
      if (idx != -1) {
        final minute = Map<String, dynamic>.from(activeList[idx] as Map);
        caseId = minute['case_file_id'] ?? minute['case_id'];
        minute['archived_at'] = isArchive ? DateTime.now().toIso8601String() : null;
        activeList[idx] = minute;
        OfflineSyncService.cacheResponse('/minutes/', activeRoot);
      }
    }

    if (caseId != null) {
      final caseMinCache = OfflineSyncService.getCachedResponse('/cases/$caseId/minutes');
      List<dynamic>? caseMinList;
      dynamic caseMinRoot;
      if (caseMinCache is List) { caseMinList = caseMinCache; caseMinRoot = caseMinCache; }
      else if (caseMinCache is Map && caseMinCache['data'] is List) {
        caseMinList = caseMinCache['data'] as List;
        caseMinRoot = caseMinCache;
      }
      if (caseMinList != null) {
        final idx = caseMinList.indexWhere((e) => e is Map && e['id'] == id);
        if (idx != -1) {
          final minuteObj = Map<String, dynamic>.from(caseMinList[idx] as Map);
          minuteObj['archived_at'] = isArchive ? DateTime.now().toIso8601String() : null;
          caseMinList[idx] = minuteObj;
          OfflineSyncService.cacheResponse('/cases/$caseId/minutes', caseMinRoot);
        }
      }
    }
  }
}
