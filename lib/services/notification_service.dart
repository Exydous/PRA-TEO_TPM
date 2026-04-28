import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Membuat instance dari plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Fungsi untuk Inisialisasi (Dijalankan saat aplikasi pertama kali buka)
  static Future<void> init() async {
    // Pengaturan icon untuk Android (menggunakan icon bawaan aplikasi)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Meminta izin notifikasi untuk Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // 2. Fungsi untuk Menembakkan Notifikasi
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Pengaturan tampilan notifikasi (Suara, Getar, dan Kepentingan)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pro_editor_channel', // ID Channel
      'Transaksi Pembayaran', // Nama Channel
      channelDescription: 'Notifikasi untuk transaksi pembelian preset',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Tampilkan notifikasinya!
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}