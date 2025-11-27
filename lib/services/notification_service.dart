import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton setup
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Pengaturan untuk Android
    // Pastikan Anda memiliki ikon bernama 'ic_launcher' di folder 'android/app/src/main/res/mipmap'
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inisialisasi plugin
    await _notificationsPlugin.initialize(settings);
  }

  // Meminta izin secara manual (wajib untuk Android 13+)
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iOSPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iOSPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Fungsi untuk menampilkan notifikasi selamat datang
  Future<void> showWelcomeNotification(String userName) async {
    // Detail spesifik untuk Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'welcome_channel', // ID Channel
          'Welcome', // Nama Channel
          channelDescription: 'Notifikasi saat registrasi berhasil',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    // Detail spesifik untuk iOS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    // Gabungkan kedua platform
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Tampilkan notifikasi
    await _notificationsPlugin.show(
      0, // ID Notifikasi
      'Registrasi Berhasil!',
      'Selamat bergabung, $userName! Akun Anda siap digunakan.',
      notificationDetails,
    );
  }
}
