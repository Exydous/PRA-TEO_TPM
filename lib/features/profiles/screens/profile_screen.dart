import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../editor/controllers/editor_controller.dart'; // Import EditorController untuk data preset
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart'; // Tambahkan ini jika AppRoutes digunakan

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi kedua controller
    final ProfileController profileController = Get.put(ProfileController());
    final EditorController editorController = Get.put(EditorController());

    editorController.loadOwnedPresets();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F), // Tema Gelap
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0F),
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Tombol Logout dipindah ke atas agar lebih rapi
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(profileController),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. HEADER PROFIL (FOTO, NAMA, EMAIL) ---
          _buildProfileHeader(profileController),

          const SizedBox(height: 20),
          const Divider(color: Colors.white10, thickness: 1, height: 1),
          const SizedBox(height: 20),

          // --- 2. JUDUL TAB KOLEKSI ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Koleksi Preset",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // --- 3. GRID PRESET YANG DIMILIKI ---
          Expanded(
            child: _buildCollectionGrid(editorController),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER PROFIL ---
  Widget _buildProfileHeader(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Obx(() {
              // Ambil huruf pertama dari nama untuk dijadikan avatar
              String initial = controller.userName.value.isNotEmpty 
                  ? controller.userName.value[0].toUpperCase() 
                  : 'P';
              return Center(
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.userName.value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
                )),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.userEmail.value,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG LOGOUT ---
  void _showLogoutDialog(ProfileController controller) {
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
        Get.back(); 
        controller.logout(); 
      },
    );
  }

  // --- WIDGET GRID KOLEKSI ---
  Widget _buildCollectionGrid(EditorController controller) {
    return Obx(() {
      if (controller.isPresetsLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (controller.ownedPresets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined, size: 60, color: Colors.white12),
              const SizedBox(height: 16),
              const Text("Koleksimu masih kosong", style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                ),
                icon: const Icon(Icons.storefront),
                label: const Text("Kunjungi Store", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Arahkan ke Preset Store (Sesuaikan dengan AppRoutes kamu)
                  Get.toNamed(AppRoutes.PRESET_STORE); // Asumsi route bernama PRESET_STORE
                },
              )
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: controller.ownedPresets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final preset = controller.ownedPresets[index];
          return _buildOwnedPresetCard(preset);
        },
      );
    });
  }

  // --- WIDGET CARD PRESET MILIK USER ---
  Widget _buildOwnedPresetCard(Map<String, dynamic> preset) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                preset['thumbnail_url'] ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black45,
                  child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${preset['author'] ?? 'Admin'}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          'Cara Penggunaan',
                          'Pilih foto terlebih dahulu di menu Editor untuk menerapkan preset ini.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.blueGrey.shade900,
                          colorText: Colors.white,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Milikmu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}