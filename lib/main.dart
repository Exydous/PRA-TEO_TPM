import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
// Import file konstanta baru kita:
import 'core/constants/api_keys.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INISIALISASI SUPABASE (Langsung menggunakan konstanta)
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
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false, 
    );
  }
}