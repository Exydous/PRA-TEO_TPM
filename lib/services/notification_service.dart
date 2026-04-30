import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; 
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
class NotificationService {
  // Membuat instance dari plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Fungsi untuk Inisialisasi (Dijalankan saat aplikasi pertama kali buka)
  static Future<void> init() async {
    // A. Inisialisasi database waktu dunia
    tz.initializeTimeZones();

    // B. Ambil lokasi waktu HP pengguna menggunakan flutter_timezone versi 5+
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    // --- [BARU] C. MEMINTA IZIN KHUSUS ANDROID ---
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Minta izin notifikasi standar (Android 13+)
      await androidPlugin.requestNotificationsPermission();
      
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint("Info: Izin alarm presisi mungkin sudah aktif atau tidak didukung: $e");
      }
    }

    // Pengaturan icon untuk Android
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

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // 2. Fungsi untuk Menembakkan Notifikasi (Notifikasi Instan / Pembelian)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pro_editor_channel', 
      'Transaksi Pembayaran', 
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

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // 3. Fungsi untuk Menjadwalkan Notifikasi (Bom Waktu Hadiah Preset)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pro_editor_scheduled_channel', 
      'Pengingat Waktu Preset', 
      channelDescription: 'Notifikasi untuk pengingat batas waktu preset hadiah',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Menembakkan notifikasi pada jam tertentu berdasarkan zona waktu lokal HP
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
  }
}