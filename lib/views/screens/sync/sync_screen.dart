import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/offline_sync_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/dashboard_controller.dart';
import '../../../../controllers/case_controller.dart';
import '../../../../controllers/task_controller.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final RxString _syncProgress = 'جاري التحضير للمزامنة...'.obs;
  final RxBool _isSyncing = false.obs;
  final RxBool _isDone = false.obs;
  final RxBool _hasError = false.obs;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback so it has context if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  Future<void> _startSync() async {
    if (StorageService.getToken() == 'offline') {
      final emailCtrl = TextEditingController();
      final passCtrl = TextEditingController(text: '123456');
      
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تسجيل الدخول للمزامنة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أنت الآن في وضع الأوفلاين. للمزامنة يجب إدخال اسم المستخدم/البريد وكلمة المرور.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني / اسم المستخدم'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false), 
              child: const Text('إلغاء')
            ),
            ElevatedButton(
              onPressed: () async {
                 Get.back(result: true); // close dialog, proceed to check
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result == true) {
         final auth = Get.find<AuthController>();
         _syncProgress.value = 'جاري تسجيل الدخول...';
         _isSyncing.value = true;
         final success = await auth.silentLogin(emailCtrl.text, passCtrl.text);
         if (success) {
            _startSync(); // now token is valid, restart sync seamlessly
         } else {
            _hasError.value = true;
            _isSyncing.value = false;
            _isDone.value = true;
            _syncProgress.value = 'البيانات المدخلة غير صحيحة. لا يمكن إتمام المزامنة.';
         }
      } else {
         Get.offAllNamed(AppRoutes.dashboard); // Cancelled
      }
      return;
    }

    _isSyncing.value = true;
    _isDone.value = false;
    _hasError.value = false;

    await OfflineSyncService.syncData((progress) {
      _syncProgress.value = progress;
      if (progress.contains('خطأ')) _hasError.value = true;
      if (progress.contains('بنجاح') || progress.contains('لا يوجد') || progress.contains('خطأ')) {
        _isSyncing.value = false;
        _isDone.value = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مزامنة البيانات'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(() {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSyncing.value) ...[
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 32),
                ],
                if (_isDone.value && !_hasError.value) ...[
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                ],
                if (_hasError.value) ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                ],
                Text(
                  _syncProgress.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_isDone.value)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_hasError.value) {
                         _startSync(); // Retry
                      } else {
                         // ── تحديث كامل لكل البيانات من السيرفر بعد المزامنة ──
                         Get.snackbar(
                           'تحديث البيانات',
                           'جاري تحديث البيانات من السيرفر...',
                           duration: const Duration(seconds: 2),
                           snackPosition: SnackPosition.BOTTOM,
                         );
                         try {
                           if (Get.isRegistered<DashboardController>()) {
                             await Get.find<DashboardController>().loadDashboard();
                           }
                           if (Get.isRegistered<CaseController>()) {
                             await Get.find<CaseController>().fetchCases();
                              await Get.find<CaseController>().fetchArchivedCases();
                              await Get.find<CaseController>().fetchArchivedSessions();
                            }
                            if (Get.isRegistered<TaskController>()) {
                              await Get.find<TaskController>().fetchTasks();
                              await Get.find<TaskController>().fetchArchivedTasks();
                           }
                         } catch (_) {}
                         Get.offAllNamed(AppRoutes.dashboard);
                      }
                    },
                    icon: Icon(_hasError.value ? Icons.refresh : Icons.home),
                    label: Text(_hasError.value ? 'إعادة المحاولة' : 'العودة للرئيسية'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
