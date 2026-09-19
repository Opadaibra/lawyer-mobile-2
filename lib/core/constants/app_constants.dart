// App constants
class AppConstants {
  // static const String baseUrl =
  // 'https://unliberalised-maximumly-brittanie.ngrok-free.dev/api';
  static const String baseUrl = 'https://lawyer-server.online/api';

  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String changePassword = '/change-password';

  // Client endpoints
  static const String clients = '/clients';

  // Case endpoints
  static const String cases = '/cases';

  // Task endpoints
  static const String tasks = '/tasks';

  // Minute endpoints
  static const String minutes = '/minutes';

  // File endpoints
  static const String filesUpload = '/files/upload';
  static const String files = '/files';

  // Team endpoints
  static const String team = '/team';

  // Client portal
  static const String clientPortal = '/client-portal/cases';

  /// إشعارات الموكل فقط (بوابة الموكل)
  static const String clientPortalNotifications =
      '/client-portal/notifications';

  /// ملخص أتعاب الموكل وسجلاتها
  static const String clientPortalFees = '/client-portal/fees';

  /// إشعارات المستخدم الحالي (من قاعدة البيانات)
  static const String notifications = '/notifications';

  /// مورد المكتب: GET / POST / PATCH (غالباً PATCH على `/offices/{id}`)
  static const String offices = '/offices';

  // SharedPreferences keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Task statuses
  static const List<String> taskStatuses = [
    'pending',
    'in_progress',
    'completed',
  ];

  // Case statuses
  static const List<String> caseStatuses = [
    'open',
    'pending',
    'closed',
    'archived',
  ];

  // App name
  static const String appName = 'مكتب المحامي';

  // Refresh endpoint
  static const String refresh = '/refresh';
}
