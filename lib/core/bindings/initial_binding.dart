import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/case_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/minute_controller.dart';
import '../../controllers/file_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../controllers/dashboard_controller.dart';
import '../../controllers/team_controller.dart';
import '../../controllers/notification_poll_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);
    Get.lazyPut<CaseController>(() => CaseController(), fenix: true);
    Get.lazyPut<TaskController>(() => TaskController(), fenix: true);
    Get.lazyPut<MinuteController>(() => MinuteController(), fenix: true);
    Get.lazyPut<FileController>(() => FileController(), fenix: true);
    Get.lazyPut<NotificationController>(
        () => NotificationController(), fenix: true);
    Get.lazyPut<search.SearchController>(
        () => search.SearchController(), fenix: true);
    Get.lazyPut<TeamController>(() => TeamController(), fenix: true);
    Get.put<NotificationPollController>(NotificationPollController(),
        permanent: true);
  }
}
