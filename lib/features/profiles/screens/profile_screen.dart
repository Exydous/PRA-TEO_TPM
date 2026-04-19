import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: Colors.black, // Tema Gelap
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              
              // --- FOTO PROFIL (Avatar Default) ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 24),

              // --- NAMA & EMAIL ---
              Obx(() => Text(
                    controller.userName.value,
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textMain
                    ),
                  )),
              const SizedBox(height: 8),
              Obx(() => Text(
                    controller.userEmail.value,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: AppColors.textSecondary
                    ),
                  )),
              
              const SizedBox(height: 48),

              // --- TOMBOL LOGOUT ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Munculkan Pop-up Konfirmasi Logout
                    Get.defaultDialog(
                      backgroundColor: const Color(0xFF1A1A1A),
                      title: 'Keluar Akun',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      middleText: 'Apakah kamu yakin ingin keluar?',
                      middleTextStyle: const TextStyle(color: Colors.white70),
                      radius: 12,
                      textCancel: 'Batal',
                      cancelTextColor: Colors.white54,
                      textConfirm: 'Keluar',
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red.shade900,
                      onConfirm: () {
                        Get.back(); // Tutup dialog
                        controller.logout(); // Jalankan fungsi logout
                      },
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'LOGOUT', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900, // Warna merah peringatan
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}