import 'dart:convert';
import 'package:get/get.dart';
import 'package:lawyer_client/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'dart:math';

class OfflineSyncService {
  static const String _syncQueueKey = 'offline_sync_queue';
  static const String _cachePrefix = 'cache_';
  static const String _idMappingKey = 'offline_id_mapping';

  // --- Caching for GET requests ---
  static Future<void> cacheResponse(String endpoint, dynamic data) async {
    final prefs = StorageService.prefs;
    final normalized = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    await prefs.setString('$_cachePrefix$normalized', jsonEncode(data));
  }

  static dynamic getCachedResponse(String endpoint) {
    final prefs = StorageService.prefs;
    final normalized = endpoint.endsWith('/')
        ? endpoint.substring(0, endpoint.length - 1)
        : endpoint;
    final jsonStr = prefs.getString('$_cachePrefix$normalized');
    if (jsonStr != null) {
      try {
        return jsonDecode(jsonStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> updateCacheObject(
      String endpoint, Map<String, dynamic> data) async {
    final cached = getCachedResponse(endpoint);
    if (cached is Map) {
      final updated = {...cached, ...data};
      await cacheResponse(endpoint, updated);
    } else {
      await cacheResponse(endpoint, data);
    }
  }

  static Future<void> appendToCacheList(
      String endpoint, Map<String, dynamic> item) async {
    final cached = getCachedResponse(endpoint);
    dynamic newCache;
    if (cached != null) {
      if (cached is List) {
        newCache = List.from(cached)..add(item);
      } else if (cached is Map) {
        newCache = Map<String, dynamic>.from(cached);
        if (newCache['data'] is List) {
          newCache['data'] = List.from(newCache['data'])..add(item);
        } else if (newCache['clients'] is List) {
          newCache['clients'] = List.from(newCache['clients'])..add(item);
        } else if (newCache['cases'] is List) {
          newCache['cases'] = List.from(newCache['cases'])..add(item);
        } else if (newCache['files'] is List) {
          newCache['files'] = List.from(newCache['files'])..add(item);
        } else if (newCache['minutes'] is List) {
          newCache['minutes'] = List.from(newCache['minutes'])..add(item);
        } else if (newCache['tasks'] is List) {
          newCache['tasks'] = List.from(newCache['tasks'])..add(item);
        } else if (newCache['sessions'] is List) {
          newCache['sessions'] = List.from(newCache['sessions'])..add(item);
        } else if (newCache['fees'] is List) {
          newCache['fees'] = List.from(newCache['fees'])..add(item);
        } else if (newCache['expenses'] is List) {
          newCache['expenses'] = List.from(newCache['expenses'])..add(item);
        }
      }
      if (newCache != null) {
        await cacheResponse(endpoint, newCache);
      }
    } else {
      await cacheResponse(endpoint, [item]);
    }
  }

  // --- Action Queue for offline creation/updating ---
  static int generateTempId() {
    // Generate a negative ID starting from -1 to -999999
    return -(DateTime.now().millisecondsSinceEpoch % 1000000);
  }

  static Future<void> queueAction({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    String? localFilePath,
    String? fileName,
    String? fileCustomEndpoint,
    Map<String, String>? fields,
    int? tempId,
  }) async {
    final prefs = StorageService.prefs;
    final queueJson = prefs.getString(_syncQueueKey);
    List<dynamic> queue = [];
    if (queueJson != null) {
      queue = jsonDecode(queueJson);
    }

    if (method == 'DELETE') {
       final parts = endpoint.split('/');
       final lastPart = parts.isNotEmpty ? parts.last : '';
       final possibleId = int.tryParse(lastPart);
       
       if (possibleId != null && possibleId < 0) {
          bool removedCreation = false;
          queue.removeWhere((item) {
             if (item['temp_id'] == possibleId) {
                removedCreation = true;
                return true;
             }
             if (item['endpoint'] != null && item['endpoint'].endsWith('/$possibleId')) {
                return true;
             }
             return false;
          });
          
          if (removedCreation) {
             await prefs.setString(_syncQueueKey, jsonEncode(queue));
             return; // Do not add DELETE to queue
          }
       }
    }

    queue.add({
      'id': DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // unique queue item id
      'method': method,
      'endpoint': endpoint,
      'data': data,
      'temp_id': tempId,
      'local_file_path': localFilePath,
      'file_name': fileName,
      'file_custom_endpoint': fileCustomEndpoint,
      'fields': fields,
      'created_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_syncQueueKey, jsonEncode(queue));
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    final prefs = StorageService.prefs;
    final queueJson = prefs.getString(_syncQueueKey);
    if (queueJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
  }

  static Future<void> removeQueueItem(String queueItemId) async {
    final prefs = StorageService.prefs;
    final queue = getSyncQueue();
    queue.removeWhere((item) => item['id'] == queueItemId);
    await prefs.setString(_syncQueueKey, jsonEncode(queue));
  }

  static Future<void> clearSyncQueue() async {
    final prefs = StorageService.prefs;
    await prefs.remove(_syncQueueKey);
  }

  // --- Synchronization Execution ---
  static Future<bool> syncData(Function(String) onProgress) async {
    // تنظيف تلقائي لأي عناصر قديمة للمصادقة/الرفرش قد تكون علقت في كاش طابور المستخدم
    final rawQueue = getSyncQueue();
    final queue = rawQueue.where((item) => !item['endpoint'].toString().contains('refresh')).toList();
    if (rawQueue.length != queue.length) {
      final prefs = StorageService.prefs;
      await prefs.setString(_syncQueueKey, jsonEncode(queue));
      print('Cleaned up ${rawQueue.length - queue.length} stale refresh items from persistent queue.');
    }

    if (queue.isEmpty) {
      onProgress("لا يوجد بيانات للمزامنة");
      return true;
    }

    final api = ApiService();

    final prefs = StorageService.prefs;
    final mappingJson = prefs.getString(_idMappingKey);
    final Map<int, int> idMapping = {};
    if (mappingJson != null) {
      final Map<String, dynamic> stored = jsonDecode(mappingJson);
      stored.forEach((k, v) => idMapping[int.parse(k)] = v as int);
    }
    print('Loaded ID Mapping: $idMapping');

    String? currentMethod;
    String? currentEndpoint;
    dynamic currentData;

    List<String> permissionErrors = [];
    List<String> syncErrors = [];

    try {
      for (int i = 0; i < queue.length; i++) {
        final item = queue[i];
        final String method = item['method'];
        String endpoint = item['endpoint'];
        dynamic data = item['data'];
        final int? tempId = item['temp_id'];

        if (method == 'DELETE') {
            final parts = endpoint.split('/');
            final lastPart = parts.isNotEmpty ? parts.last : '';
            final possibleId = int.tryParse(lastPart);
            if (possibleId != null && possibleId < 0) {
                await removeQueueItem(item['id']);
                continue; // Skip trying to delete a temp item that no longer exists
            }
        }

        currentMethod = method;
        currentEndpoint = endpoint;
        currentData = data;

        String entityName = "";
        if (data is Map) {
          entityName = data['name'] ??
              data['title'] ??
              data['case_number'] ??
              data['number'] ??
              "";
        }
        if (entityName.isEmpty && item['file_name'] != null) {
          entityName = item['file_name'];
        }

        String typeName = "بيانات";
        if (endpoint.contains('clients'))
          typeName = "الموكل";
        else if (endpoint.contains('cases'))
          typeName = "القضية";
        else if (endpoint.contains('minutes'))
          typeName = "الضبط";
        else if (endpoint.contains('tasks'))
          typeName = "المهمة";
        else if (endpoint.contains('sessions'))
          typeName = "الجلسة";
        else if (endpoint.contains('fees'))
          typeName = "الأتعاب";
        else if (endpoint.contains('team'))
          typeName = "عضو الفريق";
        else if (endpoint.contains('offices'))
          typeName = "معلومات المكتب";
        else if (method == 'UPLOAD') typeName = "الملف";

        String displayMsg =
            "جاري مزامنة $typeName ${entityName.isNotEmpty ? '($entityName)' : ''} (${i + 1}/${queue.length})";
        onProgress(displayMsg);
        print('--- $displayMsg ---');

        // Sanity fix for 'content' requirement on server if missing in old queue items
        if (data is Map) {
          if (endpoint.contains('minutes') || endpoint.contains('notes')) {
            // Use a dash or space if empty, as some servers reject empty strings for 'required' fields
            if (data['content'] == null || data['content'].toString().isEmpty) {
              data['content'] = '-';
            }
          }
          if (endpoint.contains('tasks')) {
            if (data['description'] == null ||
                data['description'].toString().isEmpty) {
              data['description'] = '-';
            }
          }
        }

        // Replace any tempId in endpoint with realId
        idMapping.forEach((temp, real) {
          endpoint = endpoint.replaceAll('/$temp', '/$real');
          endpoint = endpoint.replaceAll('=$temp', '=$real');
        });

        // Recursive replacement of temp IDs in data
        data = _replaceTempIds(data, idMapping);

        if (item['fields'] != null && item['fields'] is Map) {
          final updatedFields = Map<String, String>.from(item['fields']);
          updatedFields.forEach((key, value) {
            final intVal = int.tryParse(value);
            if (intVal != null && intVal < 0 && idMapping.containsKey(intVal)) {
              updatedFields[key] = idMapping[intVal].toString();
            }
          });
          item['fields'] = updatedFields;
          print('Updated fields for upload: $updatedFields');
        }

        print('Syncing $method $endpoint with data: $data');

        if (endpoint == AppConstants.team && method == 'POST') {
          final u = StorageService.getUser();
          final role = u?['role']?.toString().toUpperCase();
          if (role == 'VIEWER' || role == 'CLIENT') {
            permissionErrors
                .add('لم يتم إضافة العضو للفريق لأنك لا تملك الصلاحية.');
            await removeQueueItem(item['id']);
            continue;
          }
        }

        try {
          Map<String, dynamic>? response;

          if (method == 'POST') {
            response = await api.post(endpoint, data: data, isSyncCall: true);
          } else if (method == 'PUT') {
            response = await api.put(endpoint, data: data, isSyncCall: true);
          } else if (method == 'PATCH') {
            response = await api.patch(endpoint, data: data, isSyncCall: true);
          } else if (method == 'DELETE') {
            response = await api.delete(endpoint, isSyncCall: true);
          } else if (method == 'UPLOAD') {
            response = await api.uploadFile(
              filePath: item['local_file_path'],
              fileName: item['file_name'],
              customEndpoint:
                  endpoint, // Pass the transformed endpoint here if it was customized
              fields: item['fields']?.cast<String, String>(),
              isSyncCall: true,
            );
          }

          if ((method == 'POST' || method == 'UPLOAD') &&
              tempId != null &&
              tempId < 0 &&
              response != null) {
            final realId = _extractIdFromResponse(response);
            if (realId != null) {
              idMapping[tempId] = realId;

              // 1. UPDATE THE REST OF THE QUEUE IMMEDIATELY (Safety)
              // This ensures that if sync stops now, future syncs have the real IDs already in data
              final remainingQueue = getSyncQueue();
              bool queueChanged = false;
              for (var rItem in remainingQueue) {
                final rData = rItem['data'];
                if (rData != null) {
                  final updatedRData = _replaceTempIds(rData, {tempId: realId});
                  if (jsonEncode(updatedRData) != jsonEncode(rData)) {
                    rItem['data'] = updatedRData;
                    queueChanged = true;
                  }
                }
              }
              if (queueChanged) {
                await prefs.setString(_syncQueueKey, jsonEncode(remainingQueue));
              }

              // 2. Persist mapping for resuming
              final storable = <String, int>{};
              idMapping.forEach((k, v) => storable[k.toString()] = v);
              await prefs.setString(_idMappingKey, jsonEncode(storable));
              print(
                  'Mapped temp ID $tempId to real ID $realId and updated the rest of the queue');
            }
          }

          // Successfully synced, remove from queue
          await removeQueueItem(item['id']);
          print('Item synced and removed from queue');
        } catch (e) {
          print('Error syncing item $method $endpoint: $e');
          final cleanErr = e.toString().replaceAll('Exception: ', '');
          syncErrors.add('$typeName ${entityName.isNotEmpty ? "($entityName)" : ""} ($cleanErr)');
          // continue to next item
        }
      }

      if (getSyncQueue().isEmpty) {
        await prefs.remove(_idMappingKey);
      }

      if (permissionErrors.isNotEmpty || syncErrors.isNotEmpty) {
        String msg = "انتهت عملية المزامنة مع وجود بعض الملاحظات:\n";
        if (permissionErrors.isNotEmpty) {
           msg += "- تم تجاهل الإجراءات التالية بسبب الصلاحيات:\n  ${permissionErrors.toSet().join('\n  ')}\n";
        }
        if (syncErrors.isNotEmpty) {
           msg += "- فشلت مزامنة العناصر التالية وستتم المحاولة لاحقاً:\n  ${syncErrors.join('\n  ')}";
        }
        onProgress(msg.trim());
        return false;
      } else {
        onProgress("تمت المزامنة بنجاح!");
        return true;
      }
    } catch (e) {
      print('--- Global Sync Error ---');
      print('Error: $e');
      onProgress(
          "حدث خطأ غير متوقع أثناء المزامنة: ${e.toString().replaceAll('Exception: ', '')}");
      return false;
    }
  }

  static int? _extractIdFromResponse(Map<String, dynamic> response) {
    int? tryGet(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    if (response['id'] != null) return tryGet(response['id']);
    if (response['data'] != null &&
        response['data'] is Map &&
        response['data']['id'] != null) {
      return tryGet(response['data']['id']);
    }
    for (var key in [
      'case_file',
      'case',
      'client',
      'task',
      'minute',
      'note',
      'fee',
      'expense',
      'session'
    ]) {
      if (response[key] != null &&
          response[key] is Map &&
          response[key]['id'] != null) {
        return tryGet(response[key]['id']);
      }
    }
    return null;
  }

  static dynamic _replaceTempIds(dynamic data, Map<int, int> idMapping) {
    if (data is Map) {
      final Map<String, dynamic> result = {};
      data.forEach((key, value) {
        result[key] = _replaceTempIds(value, idMapping);
      });
      return result;
    } else if (data is List) {
      return data.map((e) => _replaceTempIds(e, idMapping)).toList();
    } else if (data is int && data < 0 && idMapping.containsKey(data)) {
      return idMapping[data];
    } else if (data is String) {
      final intVal = int.tryParse(data);
      if (intVal != null && intVal < 0 && idMapping.containsKey(intVal)) {
        return idMapping[intVal].toString();
      }
    }
    return data;
  }
}
