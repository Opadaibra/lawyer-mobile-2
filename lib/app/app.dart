import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import '../core/bindings/initial_binding.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/services/storage_service.dart';
import '../data/services/notification_service.dart';
import '../core/localization/app_translations.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class LawyerApp extends StatefulWidget {
  const LawyerApp({super.key});

  @override
  State<LawyerApp> createState() => _LawyerAppState();
}

class _LawyerAppState extends State<LawyerApp> {
  bool _initialized = false;
  bool _isLoggedIn = false;
  bool _isClient = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await StorageService.init();
    await NotificationService.initialize();
    final userData = StorageService.getUser();
    final role = userData?['role']?.toString().toUpperCase();
    final isOffline = StorageService.isOfflineMode();
    setState(() {
      _isLoggedIn = StorageService.isLoggedIn() || isOffline;
      _isClient = role == 'CLIENT';
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: StorageService.getThemeMode() == 'dark' ? ThemeMode.dark : ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: _isLoggedIn
          ? (_isClient ? AppRoutes.clientPortal : AppRoutes.dashboard)
          : AppRoutes.login,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      locale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      defaultTransition: Transition.cupertino,
      navigatorObservers: [routeObserver],
    );
  }
}

