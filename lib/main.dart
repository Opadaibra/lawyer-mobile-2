import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/app.dart';
import 'data/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialization
  await StorageService.init();
  await initializeDateFormatting('ar', null);
  tz.initializeTimeZones();
  
  runApp(const LawyerApp());
}
