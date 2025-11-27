// lib/utils/time_util.dart

import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimeUtil {
  // Panggil ini di main.dart Anda SEBELUM runApp()
  static void initializeTimezones() {
    tz.initializeTimeZones();
  }

  // Helper untuk memformat
  static String _format(DateTime dt, String loc) {
    final location = tz.getLocation(loc);
    final zonedTime = tz.TZDateTime.from(dt, location);
    // Format: 10 Nov 2025, 08:30
    return DateFormat('d MMM y, HH:mm').format(zonedTime);
  }

  // Fungsi utama yang akan Anda panggil
  static Map<String, String> getFormattedTimezones(DateTime utcTime) {
    return {
      'WIB': '${_format(utcTime, 'Asia/Jakarta')} (WIB)',
      'WITA': '${_format(utcTime, 'Asia/Makassar')} (WITA)',
      'WIT': '${_format(utcTime, 'Asia/Jayapura')} (WIT)',
      'London': '${_format(utcTime, 'Europe/London')} (GMT/BST)',
    };
  }
}
