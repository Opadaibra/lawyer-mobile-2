import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/case_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/task_model.dart';
import '../../data/models/sub_resource_models.dart';
import '../../app/app.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const List<String> syrianMonths = [
    'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
    'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'
  ];

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshDashboard();
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshDashboard();
        }
      } catch (_) {}
    }
  }

  @override
  void didPopNext() {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
    } catch (_) {}
  }

  void _scrollToTasks() {
    Future.delayed(const Duration(milliseconds: 150), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = Get.put(DashboardController());
    final auth = Get.find<AuthController>();

    return RefreshIndicator(
      onRefresh: () => dash.refreshDashboard(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Welcome
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome_back'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      auth.userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'calendar'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Obx(() {
                      // Accessing these variables inside Obx ensures the calendar rebuilds when data changes
                      final _ = dash.allSessions.length;
                      final __ = dash.allTasks.length;
                      return TableCalendar(
                        locale: 'ar',
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: dash.focusedDay.value,
                        selectedDayPredicate: (day) => isSameDay(dash.selectedDay.value, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          dash.selectedDay.value = selectedDay;
                          dash.focusedDay.value = focusedDay;
                          _scrollToTasks();
                        },
                        eventLoader: (day) => dash.filterItemsByDate(day),
                        calendarFormat: CalendarFormat.month,
                        rowHeight: 46,
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          cellMargin: const EdgeInsets.all(4),
                          todayDecoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                          selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          markerDecoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextFormatter: (date, locale) {
                            return '${date.month} - ${DashboardScreen.syrianMonths[date.month - 1]}';
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Past Sessions Section
            Obx(() {
              final past = dash.pastSessions;
              if (past.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'past_sessions'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: past.length,
                    itemBuilder: (context, index) {
                      final session = past[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        ),
                        child: ListTile(
                          onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'id': session.caseId}),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.gavel, color: Colors.red),
                          ),
                          title: Text('جلسة: ${session.caseNumber ?? "بدون رقم"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session.clientName ?? 'موعد جلسة', maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                AppHelpers.formatDateTime(session.date),
                                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          trailing: TextButton.icon(
                            onPressed: () => _showPostponeDialog(context, session),
                            icon: const Icon(Icons.forward, size: 16),
                            label: Text('transfer'.tr, style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),

            // Statistics Section
            Obx(() => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    _CompactStatCard(
                      title: 'cases'.tr,
                      value: dash.totalCases.value.toString(),
                      icon: Icons.folder,
                      color: Colors.blue,
                      onTap: () => Get.toNamed(AppRoutes.cases),
                    ),
                    _CompactStatCard(
                      title: 'uncompleted_tasks'.tr,
                      value: dash.pendingTasks.value.toString(),
                      icon: Icons.assignment,
                      color: Colors.purple,
                      onTap: () => Get.toNamed(AppRoutes.tasks),
                    ),
                    _CompactStatCard(
                      title: 'sessions'.tr,
                      value: dash.totalSessions.value.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.red,
                      onTap: () => Get.toNamed(AppRoutes.allSessions),
                    ),
                  ],
                )),

            const SizedBox(height: 24),

            // Tasks section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'tasks_for_day'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.tasks),
                  child: Text('view_all'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Obx(() {
              // Accessing these variables inside Obx ensures the list rebuilds when data changes
              final _ = dash.allSessions.length;
              final __ = dash.allTasks.length;
              final filteredItems = dash.filterItemsByDate(dash.selectedDay.value);
              if (filteredItems.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('no_tasks_for_selected_day'.tr, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  if (item is TaskModel) {
                    final task = item;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => Get.toNamed(AppRoutes.taskDetail, arguments: {'task': task}),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.assignment_outlined, color: AppTheme.accent),
                        ),
                        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(task.clientName ?? task.caseNumber ?? 'task'.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dash.getStatusColor(task.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            task.status.tr,
                            style: TextStyle(color: dash.getStatusColor(task.status), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  } else if (item is SessionModel) {
                    final session = item;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red, width: 0.5)),
                      child: ListTile(
                        onTap: () => Get.toNamed(AppRoutes.caseDetail, arguments: {'id': session.caseId}),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.gavel, color: Colors.red),
                        ),
                        title: Text('جلسة: ${session.caseNumber ?? "بدون رقم"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(session.clientName ?? 'موعد جلسة', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(height: 2),
                            Text(
                              AppHelpers.formatTimeOnly(session.date),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPostponeDialog(BuildContext context, SessionModel s) {
    final dateCtrl = TextEditingController();
    final decisionCtrl = TextEditingController();
    final caseCtrl = Get.find<CaseController>();

    Get.dialog(AlertDialog(
      title: Text('postpone'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatefulBuilder(
            builder: (context, setState) => TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'new_date'.tr,
                suffixIcon: const Icon(Icons.calendar_month),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    final combined = DateTime(date.year, date.month, date.day,
                            time.hour, time.minute)
                        .toUtc();
                    setState(() => dateCtrl.text = combined
                        .toIso8601String()
                        .replaceFirst('T', ' ')
                        .substring(0, 19));
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: decisionCtrl,
            decoration: InputDecoration(
              labelText: 'decisions'.tr,
              hintText: 'ماذا قررت المحكمة في هذه الجلسة؟',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        Obx(() => caseCtrl.isSubmitting.value
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: () async {
                  if (dateCtrl.text.isEmpty) {
                    Get.snackbar('error'.tr, 'يرجى اختيار التاريخ الجديد');
                    return;
                  }
                  // أغلق الديالوغ فوراً قبل أي عملية أخرى
                  Get.back();
                  final success = await caseCtrl.postponeSession(s.id, s.caseId, {
                    'new_date': dateCtrl.text,
                    'decisions': decisionCtrl.text,
                  });
                  // ملاحظة: postponeSession يستدعي refreshDashboard من الداخل - لا حاجة لاستدعائه مرة ثانية
                  if (success) {
                    Get.snackbar(
                      'success'.tr,
                      'postpone_success'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: Text('transfer'.tr),
              )),
      ],
    ));
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
