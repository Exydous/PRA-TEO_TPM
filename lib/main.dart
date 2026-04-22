import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:hive_flutter/hive_flutter.dart'; // [BARU] Import Hive
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_keys.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. LOAD file .env terlebih dahulu
  await dotenv.load(fileName: ".env");
  
  // 2. INISIALISASI SUPABASE (TETAP DIPERTAHANKAN)
  // Digunakan murni sebagai gudang Preset & Draft (Akses Publik/Anon)
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  // 3. [BARU] INISIALISASI HIVE & BUKA KOTAK RAHASIA
  // Digunakan khusus untuk sistem Auth Lokal
  await Hive.initFlutter();
  await Hive.openBox('authBox');

  // 4. [BARU] CEK STATUS LOGIN
  // Mengecek apakah ada user yang sedang aktif di memori HP
  final authBox = Hive.box('authBox');
  final bool isLoggedIn = authBox.containsKey('currentUser');
  
  // Jalankan aplikasi sambil mengirimkan status login
  runApp(ProEditorApp(isLoggedIn: isLoggedIn));
}

class ProEditorApp extends StatelessWidget {
  final bool isLoggedIn; // Menerima status login dari fungsi main

  const ProEditorApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pro Editor',
      theme: AppTheme.darkTheme,
      // [BARU] Rute Pintar: Jika sudah login langsung ke Editor/Home, jika belum ke Login
      // Catatan: Pastikan 'AppRoutes.HOME' sesuai dengan nama rute halaman utamamu.
      initialRoute: isLoggedIn ? AppRoutes.MAIN : AppRoutes.LOGIN,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false, 
    );
  }
}