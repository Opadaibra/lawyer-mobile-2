import 'package:get/get.dart';
import '../../views/screens/auth/login_screen.dart';
import '../../views/screens/auth/register_screen.dart';
import '../../views/screens/auth/forgot_password_screen.dart';
import '../../views/screens/dashboard_screen.dart';
import '../../views/screens/main_navigation_screen.dart';
import '../../views/screens/archive_screen.dart';
import '../../views/screens/clients/clients_screen.dart';
import '../../views/screens/clients/client_detail_screen.dart';
import '../../views/screens/clients/client_form_screen.dart';
import '../../views/screens/cases/cases_screen.dart';
import '../../views/screens/cases/case_detail_screen.dart';
import '../../views/screens/cases/case_form_screen.dart';
import '../../views/screens/sessions/all_sessions_screen.dart';
import '../../views/screens/tasks/tasks_screen.dart';
import '../../views/screens/tasks/task_detail_screen.dart';
import '../../views/screens/tasks/task_form_screen.dart';
import '../../views/screens/minutes/minutes_screen.dart';
import '../../views/screens/minutes/minute_form_screen.dart';
import '../../views/screens/minutes/minute_detail_screen.dart';
import '../../views/screens/files/files_screen.dart';
import '../../views/screens/files/file_viewer_screen.dart';
import '../../views/screens/notifications_screen.dart';
import '../../views/screens/search_screen.dart';
import '../../views/screens/profile_screen.dart';
import '../../views/screens/team/team_screen.dart';
import '../../views/screens/client_portal/client_portal_screen.dart';
import '../../views/screens/client_portal/client_portal_case_detail_screen.dart';
import '../../views/screens/office/office_info_screen.dart';
import '../../views/screens/office/about_office_screen.dart';
import '../../views/screens/sync/sync_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const MainNavigationScreen(),
    ),
    // Clients
    GetPage(name: AppRoutes.clients, page: () => const ClientsScreen()),
    GetPage(name: AppRoutes.clientDetail, page: () => const ClientDetailScreen()),
    GetPage(name: AppRoutes.clientForm, page: () => const ClientFormScreen()),
    // Cases
    GetPage(name: AppRoutes.cases, page: () => const CasesScreen()),
    GetPage(name: AppRoutes.caseDetail, page: () => const CaseDetailScreen()),
    GetPage(name: AppRoutes.caseForm, page: () => const CaseFormScreen()),
    GetPage(name: AppRoutes.allSessions, page: () => const AllSessionsScreen()),
    // Tasks
    GetPage(name: AppRoutes.tasks, page: () => const TasksScreen()),
    GetPage(name: AppRoutes.taskDetail, page: () => const TaskDetailScreen()),
    GetPage(name: AppRoutes.taskForm, page: () => const TaskFormScreen()),
    // Minutes
    GetPage(name: AppRoutes.minutes, page: () => const MinutesScreen()),
    GetPage(name: AppRoutes.minuteDetail, page: () => const MinuteDetailScreen()),
    GetPage(name: AppRoutes.minuteForm, page: () => const MinuteFormScreen()),
    // Files
    GetPage(name: AppRoutes.files, page: () => const FilesScreen()),
    GetPage(name: AppRoutes.fileViewer, page: () => const FileViewerScreen()),
    // Other
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen()),
    GetPage(name: AppRoutes.search, page: () => const SearchScreen()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(name: AppRoutes.archive, page: () => const ArchiveScreen()),
    GetPage(name: AppRoutes.team, page: () => const TeamScreen()),
    GetPage(name: AppRoutes.officeInfo, page: () => const OfficeInfoScreen()),
    GetPage(name: AppRoutes.clientPortal, page: () => const ClientPortalScreen()),
    GetPage(
        name: AppRoutes.clientPortalCaseDetail,
        page: () => const ClientPortalCaseDetailScreen()),
    GetPage(name: AppRoutes.aboutOffice, page: () => const AboutOfficeScreen()),
    GetPage(name: AppRoutes.syncData, page: () => const SyncScreen()),
  ];
}
