import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:tugas_akhir/services/notification_service.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_keys.dart'; 
// Import ProfileController agar main.dart bisa memantau perubahan status
import 'features/profiles/controllers/profile_controller.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  await NotificationService.init();
  
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  await Hive.initFlutter();
  await Hive.openBox('authBox');

  final authBox = Hive.box('authBox');
  final bool isLoggedIn = authBox.containsKey('currentUser');

  // Inisialisasi ProfileController di awal agar datanya tersedia untuk filter warna
  Get.put(ProfileController());
  
  runApp(ProEditorApp(isLoggedIn: isLoggedIn));
}

class ProEditorApp extends StatelessWidget {
  final bool isLoggedIn;

  const ProEditorApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Kita gunakan Obx di sini agar saat user ganti jenis buta warna di profil,
    // seluruh warna aplikasi langsung berubah otomatis tanpa restart!
    return Obx(() {
      final profileCtrl = Get.find<ProfileController>();
      final String colorBlindType = profileCtrl.selectedColorBlindType.value;

      return ColorFiltered(
        colorFilter: _getColorBlindFilter(colorBlindType),
        child: GetMaterialApp(
          title: 'Pro Editor',
          theme: AppTheme.darkTheme,
          initialRoute: isLoggedIn ? AppRoutes.MAIN : AppRoutes.LOGIN,
          getPages: AppPages.pages,
          debugShowCheckedModeBanner: false, 
        ),
      );
    });
  }

  // --- [SISTEM FILTER WARNA GLOBAL] ---
  ColorFilter _getColorBlindFilter(String type) {
    switch (type) {
      case 'Protanopia (Merah)':
        return const ColorFilter.matrix([
          0.567, 0.433, 0.000, 0.000, 0.000,
          0.558, 0.442, 0.000, 0.000, 0.000,
          0.000, 0.242, 0.758, 0.000, 0.000,
          0.000, 0.000, 0.000, 1.000, 0.000,
        ]);
      case 'Deuteranopia (Hijau)':
        return const ColorFilter.matrix([
          0.625, 0.375, 0.000, 0.000, 0.000,
          0.700, 0.300, 0.000, 0.000, 0.000,
          0.000, 0.300, 0.700, 0.000, 0.000,
          0.000, 0.000, 0.000, 1.000, 0.000,
        ]);
      case 'Tritanopia (Biru)':
        return const ColorFilter.matrix([
          0.950, 0.050, 0.000, 0.000, 0.000,
          0.000, 0.433, 0.567, 0.000, 0.000,
          0.000, 0.475, 0.525, 0.000, 0.000,
          0.000, 0.000, 0.000, 1.000, 0.000,
        ]);
      case 'Monochromacy (Total)':
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      default:
        // Jika Normal, gunakan filter transparan (tidak ada perubahan)
        return const ColorFilter.mode(Colors.transparent, BlendMode.multiply);
    }
  }
}