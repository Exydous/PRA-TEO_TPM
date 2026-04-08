import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized(); // load .env sebelum runApp
  
  await dotenv.load(fileName: ".env"); // load .env file isi API
  
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
      debugShowCheckedModeBanner: false, // debug hapus banner di pojok kanan atas
    );
  }
}