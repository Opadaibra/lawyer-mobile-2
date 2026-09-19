import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MainNavigationController extends GetxController {
  final currentIndex = 1.obs; // Default to Home (Index 1)

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  Future<void> openSystemCalendar() async {
    Uri calendarUri;
    if (Platform.isAndroid) {
      calendarUri = Uri.parse("content://com.android.calendar/time/");
    } else if (Platform.isIOS) {
      calendarUri = Uri.parse("calshow://");
    } else {
      calendarUri = Uri.parse("https://calendar.google.com");
    }

    if (await canLaunchUrl(calendarUri)) {
      await launchUrl(calendarUri);
    } else {
      Get.snackbar('Error', 'Could not open calendar');
    }
  }
}
