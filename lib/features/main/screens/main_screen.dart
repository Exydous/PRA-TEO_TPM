import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';

// Import Controller dan Halaman Tab
import '../controllers/main_controller.dart';
import '../../editor/screens/home_screen.dart';
import '../../utilities/screens/utilities_screen.dart';
import '../../feedback/screens/feedback_screen.dart';
import '../../profiles/screens/profile_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  // Memanggil controller (dependency injection)
  final MainController controller = Get.put(MainController());

  // Daftar halaman yang akan ditampilkan sesuai urutan tab
  final List<Widget> _pages = [
    const HomeScreen(),
    const UtilitiesScreen(),
    const FeedbackScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro-Editor'),
      ),
      // Obx akan merender ulang HANYA bagian body saat tab berganti
      body: Obx(() => _pages[controller.selectedIndex.value]),
      
      // Obx juga merender ulang warna ikon tab yang aktif
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed, // Mencegah ikon bergeser-geser
          backgroundColor: AppColors.surface, // warna latar belakang tab bawah
          selectedItemColor: AppColors.primary, // warna ikon tab yang aktif
          unselectedItemColor: AppColors.textSecondary, // warna ikon tab yang tidak aktif
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Gallery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Utilities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.feedback_outlined),
              activeIcon: Icon(Icons.feedback),
              label: 'Feedback',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}