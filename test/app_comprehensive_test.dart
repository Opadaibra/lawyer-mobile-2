import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lawyer_client/data/services/storage_service.dart';
import 'package:lawyer_client/data/services/offline_sync_service.dart';
import 'package:lawyer_client/data/models/user_model.dart';
import 'package:lawyer_client/data/models/client_model.dart';
import 'package:lawyer_client/data/models/case_model.dart';
import 'package:lawyer_client/data/models/task_model.dart';
import 'package:lawyer_client/data/models/minute_model.dart';

void main() {
  // Setup SharedPreferences mock environment before each test
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  group('StorageService Tests', () {
    test('Should correctly manage user login tokens', () async {
      expect(StorageService.isLoggedIn(), isFalse);
      expect(StorageService.getToken(), isNull);

      await StorageService.setToken('test_jwt_token_123');
      expect(StorageService.isLoggedIn(), isTrue);
      expect(StorageService.getToken(), 'test_jwt_token_123');

      await StorageService.removeToken();
      expect(StorageService.isLoggedIn(), isFalse);
      expect(StorageService.getToken(), isNull);
    });

    test('Should correctly manage user session profile payload', () async {
      final mockUser = {
        'id': 10,
        'name': 'المهندس أحمد',
        'email': 'ahmad@example.com',
        'role': 'LAWYER',
        'office_name': 'مكتب العدل للمحاماة',
      };

      expect(StorageService.getUser(), isNull);

      await StorageService.setUser(mockUser);
      final retrieved = StorageService.getUser();
      expect(retrieved, isNotNull);
      expect(retrieved!['id'], 10);
      expect(retrieved['name'], 'المهندس أحمد');
      expect(retrieved['role'], 'LAWYER');

      await StorageService.removeUser();
      expect(StorageService.getUser(), isNull);
    });

    test('Should correctly handle theme settings and offline mode flags', () async {
      expect(StorageService.getThemeMode(), 'light'); // Default
      await StorageService.setThemeMode('dark');
      expect(StorageService.getThemeMode(), 'dark');

      expect(StorageService.isOfflineMode(), isFalse); // Default
      await StorageService.setOfflineMode(true);
      expect(StorageService.isOfflineMode(), isTrue);
    });
  });

  group('OfflineSyncService Caching & Queue Deduplication Tests', () {
    test('Should cache and retrieve API GET response payloads', () async {
      final endpoint = '/api/clients';
      final mockData = [
        {'id': 1, 'name': 'خالد العتيبي'},
        {'id': 2, 'name': 'سليمان الحربي'}
      ];

      expect(OfflineSyncService.getCachedResponse(endpoint), isNull);

      await OfflineSyncService.cacheResponse(endpoint, mockData);
      final cached = OfflineSyncService.getCachedResponse(endpoint);
      expect(cached, isNotNull);
      expect(cached, isList);
      expect(cached.length, 2);
      expect(cached[0]['name'], 'خالد العتيبي');
    });

    test('Should append newly created items offline directly to cached lists', () async {
      final endpoint = '/cases';
      final initialList = {
        'data': [
          {'id': 1, 'title': 'قضية إخلاء عقار'}
        ]
      };

      await OfflineSyncService.cacheResponse(endpoint, initialList);

      final newItem = {'id': -999, 'title': 'قضية تعويضات مالية'};
      await OfflineSyncService.appendToCacheList(endpoint, newItem);

      final updated = OfflineSyncService.getCachedResponse(endpoint);
      expect(updated, isNotNull);
      expect(updated['data'], isList);
      expect(updated['data'].length, 2);
      expect(updated['data'][1]['id'], -999);
      expect(updated['data'][1]['title'], 'قضية تعويضات مالية');
    });

    test('Should queue POST and UPDATE actions in the offline synchronization queue', () async {
      expect(OfflineSyncService.getSyncQueue().isEmpty, isTrue);

      await OfflineSyncService.queueAction(
        method: 'POST',
        endpoint: '/cases',
        data: {'title': 'قضية إثبات ملكية'},
        tempId: -1050,
      );

      final queue = OfflineSyncService.getSyncQueue();
      expect(queue.length, 1);
      expect(queue[0]['method'], 'POST');
      expect(queue[0]['endpoint'], '/cases');
      expect(queue[0]['temp_id'], -1050);
      expect(queue[0]['data']['title'], 'قضية إثبات ملكية');
    });

    test('DEDUPLICATION: Deleting a locally-created unsynced item must remove its POST request and NOT add a DELETE request', () async {
      final tempId = -888777;
      
      // 1. Queue a POST request for a new client created offline
      await OfflineSyncService.queueAction(
        method: 'POST',
        endpoint: '/clients',
        data: {'name': 'عميل مؤقت أوفلاين'},
        tempId: tempId,
      );

      // Verify the post is in the queue
      var queue = OfflineSyncService.getSyncQueue();
      expect(queue.length, 1);
      expect(queue[0]['method'], 'POST');
      expect(queue[0]['temp_id'], tempId);

      // 2. The user decides to delete the item before going online.
      // A DELETE request is sent to /clients/-888777
      await OfflineSyncService.queueAction(
        method: 'DELETE',
        endpoint: '/clients/$tempId',
      );

      // 3. Verify deduplication logic:
      // - The original POST creation request should be completely removed.
      // - The DELETE request should NOT be added to the queue since the item was never sent to the server.
      queue = OfflineSyncService.getSyncQueue();
      expect(queue.isEmpty, isTrue); // Cleaned up and silent deletion!
    });
  });

  group('Data Models JSON Mapping Tests', () {
    test('UserModel should correctly parse user fields and check authorizations', () {
      final json = {
        'id': 5,
        'name': 'سعد الحربي',
        'email': 'saad@office.com',
        'role': 'LAWYER',
        'office': {
          'name': 'مكتب سعد وشريكه',
          'address': 'الرياض، المملكة العربية السعودية',
          'phone': '0500000000'
        }
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 5);
      expect(user.name, 'سعد الحربي');
      expect(user.isClient, isFalse);
      expect(user.canMutateOfficeContent, isTrue);
      expect(user.officeName, 'مكتب سعد وشريكه');
      expect(user.officeAddress, 'الرياض، المملكة العربية السعودية');
      expect(user.officePhone, '0500000000');

      // Test CLIENT permissions
      final clientUser = UserModel.fromJson({
        'id': 6,
        'name': 'عبدالله العميل',
        'role': 'CLIENT'
      });
      expect(clientUser.isClient, isTrue);
      expect(clientUser.canMutateOfficeContent, isFalse);
    });

    test('ClientModel should parse properly and format picture paths', () {
      final json = {
        'id': 12,
        'name': 'فيصل بن خالد',
        'phone': '966555555',
        'email': 'faisal@client.com',
        'power_of_attorney_number': '123456/A',
        'is_starred': true,
        'profile_picture': 'uploads/clients/12.jpg'
      };

      final client = ClientModel.fromJson(json);
      expect(client.id, 12);
      expect(client.name, 'فيصل بن خالد');
      expect(client.isStarred, isTrue);
      expect(client.powerOfAttorneyNumber, '123456/A');
      expect(client.profilePictureUrl, 'http://127.0.0.1:8000/storage/uploads/clients/12.jpg');
    });

    test('CaseModel, TaskModel, and MinuteModel should parse correctly', () {
      // 1. TaskModel parsing
      final taskJson = {
        'id': 20,
        'title': 'كتابة لائحة اعتراضية',
        'description': 'مراجعة أوراق القضية وإعداد الرد القانوني قبل الموعد',
        'status': 'PENDING',
        'due_date': '2026-06-01'
      };

      final task = TaskModel.fromJson(taskJson);
      expect(task.id, 20);
      expect(task.title, 'كتابة لائحة اعتراضية');
      expect(task.status, 'PENDING'); // Default pending behavior

      // 2. MinuteModel parsing
      final minuteJson = {
        'id': 30,
        'title': 'جلسة صلح أولى',
        'content': 'تم النقاش بين الطرفين وتم التوافق المبدئي على مهلة أسبوعين',
        'case_file_id': 100,
        'created_at': '2026-05-18T12:00:00Z'
      };

      final minute = MinuteModel.fromJson(minuteJson);
      expect(minute.id, 30);
      expect(minute.title, 'جلسة صلح أولى');
      expect(minute.content, 'تم النقاش بين الطرفين وتم التوافق المبدئي على مهلة أسبوعين');
      expect(minute.caseFileId, 100);
    });
  });
}
