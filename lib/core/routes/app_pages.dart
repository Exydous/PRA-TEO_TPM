import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/editor/screens/editor_screen.dart';
import '../../features/utilities/preset_store/screens/preset_store_screen.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.MAIN,
      page: () => MainScreen(),
    ),
    GetPage(
      name: AppRoutes.PRESET_STORE,
      page: () => const PresetStoreScreen(),
    ),
    // TAMBAHKAN BLOK INI
    GetPage(
      name: AppRoutes.EDITOR,
      page: () => const EditorScreen(),
    ),
  ];
}