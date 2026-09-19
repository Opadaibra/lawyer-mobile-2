import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'cases/cases_screen.dart';
import 'minutes/minutes_screen.dart';
import 'clients/clients_screen.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/offline_sync_service.dart';
import '../../controllers/dashboard_controller.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CasesScreen(),
    const MinutesScreen(),
    const ClientsScreen(),
  ];

  final List<String> _titles = [
    'home',
    'cases',
    'minutes',
    'clients',
  ];

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
    Get.back(); // إغلاق الدراور
    if (index == 0) {
      try {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshDashboard();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: _currentIndex == 0 
        ? _buildHomeAppBar(context, auth) 
        : _buildDefaultAppBar(_titles[_currentIndex].tr),
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: _onNavigate,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            try {
              if (Get.isRegistered<DashboardController>()) {
                Get.find<DashboardController>().refreshDashboard();
              }
            } catch (_) {}
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'home'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: 'cases'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.description_outlined),
            activeIcon: const Icon(Icons.description),
            label: 'minutes'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: 'clients'.tr,
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 
        ? FloatingActionButton(
            heroTag: 'main_dashboard_fab',
            onPressed: () => Get.toNamed(AppRoutes.taskForm),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add),
          )
        : null,
    );
  }

  AppBar _buildHomeAppBar(BuildContext context, AuthController auth) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text('home'.tr),
      actions: [
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: 'archive'.tr,
          onPressed: () => Get.toNamed(AppRoutes.archive),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          onPressed: () => Get.toNamed(AppRoutes.notifications),
        ),
        PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          onSelected: (value) {
            if (value == 'office') Get.toNamed(AppRoutes.officeInfo);
            if (value == 'team') Get.toNamed(AppRoutes.team);
            if (value == 'change_password') _showChangePasswordDialog(context, auth);
            if (value == 'logout') _confirmLogout(auth);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'office', child: ListTile(leading: const Icon(Icons.business), title: Text('office_info'.tr), dense: true)),
            PopupMenuItem(value: 'team', child: ListTile(leading: const Icon(Icons.group), title: Text('team'.tr), dense: true)),
            PopupMenuItem(value: 'change_password', child: ListTile(leading: const Icon(Icons.lock_outline), title: Text('change_password'.tr), dense: true)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'logout', child: ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: Text('logout'.tr, style: const TextStyle(color: Colors.red)), dense: true)),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthController auth) {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('change_password'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'current_password'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'new_password'.tr),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(labelText: 'confirm_password'.tr),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          Obx(() => ElevatedButton(
            onPressed: auth.isLoading.value ? null : () async {
              if (newPass.text != confirmPass.text) {
                Get.snackbar('error'.tr, 'passwords_dont_match'.tr);
                return;
              }
              final success = await auth.changePassword(
                currentPassword: currentPass.text,
                newPassword: newPass.text,
                confirmPassword: confirmPass.text,
              );
              if (success) {
                Get.back(); // إغلاق الديالوغ أولاً
                Get.snackbar('success'.tr, 'password_changed_success'.tr); // ثم إظهار الرسالة
              }
            },
            child: auth.isLoading.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('save'.tr),
          )),
        ],
      ),
    );
  }

  AppBar _buildDefaultAppBar(String title) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }
  void _confirmLogout(AuthController auth) {
    Get.dialog(AlertDialog(
      title: Text('logout'.tr),
      content: const Text('سيتم تسجيل الخروج. انتبه: أي بيانات لم يتم مزامنتها مسبقاً قد يتم فقدانها.'),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            Get.back();
            auth.logout();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('logout'.tr),
        ),
      ],
    ));
  }
}

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const AppDrawer({super.key, required this.currentIndex, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primary, size: 40),
            ),
            accountName: Obx(() => Text(auth.userName)),
            accountEmail: Obx(() => Text(auth.userEmail)),
          ),
          _DrawerTile(
            icon: Icons.home_outlined, 
            label: 'home'.tr, 
            selected: currentIndex == 0,
            onTap: () => onNavigate(0)
          ),
          _DrawerTile(
            icon: Icons.task_outlined, 
            label: 'tasks'.tr, 
            onTap: () { 
              Get.back(); 
              Get.toNamed(AppRoutes.tasks); 
            }
          ),
          _DrawerTile(
            icon: Icons.folder_outlined, 
            label: 'cases'.tr, 
            selected: currentIndex == 1,
            onTap: () => onNavigate(1)
          ),
          _DrawerTile(
            icon: Icons.description_outlined, 
            label: 'minutes'.tr, 
            selected: currentIndex == 2,
            onTap: () => onNavigate(2)
          ),
          _DrawerTile(
            icon: Icons.people_outline, 
            label: 'clients'.tr, 
            selected: currentIndex == 3,
            onTap: () => onNavigate(3)
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.archive_outlined, 
            label: 'archive'.tr, 
            onTap: () { 
              Get.back(); 
              Get.toNamed(AppRoutes.archive); 
            }
          ),
          _DrawerTile(
            icon: Icons.info_outline, 
            label: 'about_office'.tr, 
            onTap: () { 
              Get.back(); 
              Get.toNamed(AppRoutes.aboutOffice); 
            }
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.attach_file, 
            label: 'files'.tr, 
            onTap: () { 
              Get.back(); 
              Get.toNamed(AppRoutes.files); 
            }
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.sync, 
            label: 'المزامنة (رفع البيانات)'.tr, 
            onTap: () { 
              Get.back(); 
              Get.toNamed(AppRoutes.syncData); 
            }
          ),
          const Spacer(),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout, 
            label: 'logout'.tr, 
            onTap: () {
              Get.back(); // close drawer
              Get.dialog(AlertDialog(
                title: Text('logout'.tr),
                content: const Text('سيتم تسجيل الخروج. انتبه: أي بيانات لم يتم مزامنتها مسبقاً قد يتم فقدانها.'),
                actions: [
                  TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      auth.logout();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('logout'.tr),
                  ),
                ],
              ));
            }
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerTile({
    required this.icon, 
    required this.label, 
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppTheme.primary : Colors.grey[700]), 
      title: Text(label, style: TextStyle(
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? AppTheme.primary : Colors.black87,
      )), 
      selected: selected,
      onTap: onTap,
    );
  }
}
