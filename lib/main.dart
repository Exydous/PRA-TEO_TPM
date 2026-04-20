import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_keys.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. LOAD file .env terlebih dahulu
  await dotenv.load(fileName: ".env");
  
  // 2. INISIALISASI SUPABASE
  // Sekarang ApiKeys.supabaseUrl akan mengambil nilai dari dotenv secara otomatis
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );
  
  runApp(const ProEditorApp());
}

class ProEditorApp extends StatelessWidget {
  const ProEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pro Editor',
      theme: AppTheme.darkTheme, // UI Editor Profesional gelap Anda sudah terpasang di sini
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false, 
    );
  }
}