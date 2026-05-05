import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../editor/controllers/editor_controller.dart'; 
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart'; 
import 'dart:async';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());
    final EditorController editorController = Get.put(EditorController(), permanent: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F), // warna latar belakang gelap untuk profil
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0F), // warna appbar
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // warna teks putih untuk judul
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // warna ikon back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), // warna ikon logout
            onPressed: () => _showLogoutDialog(profileController),
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(profileController),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, thickness: 1, height: 1), // warna divider putih transparan
            const SizedBox(height: 24),

            // --- 1. SECTION PENGATURAN APLIKASI [BARU] ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Pengaturan Aplikasi",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5), // warna teks pengaturan aplikasi
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(profileController),

            const SizedBox(height: 32),
            const Divider(color: Colors.white10, thickness: 1, height: 1), // warna divider putih transparan
            const SizedBox(height: 24),

            // --- 2. KOLEKSI PRESET ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Koleksi Preset",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5), // warna teks koleksi preset
              ),
            ),
            const SizedBox(height: 16),
            _buildCollectionGrid(editorController),

            const SizedBox(height: 32),
            const Divider(color: Colors.white10, thickness: 1, height: 1), // warna divider putih transparan
            const SizedBox(height: 24),

            // --- 3. SARAN & KESAN ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Saran & Kesan",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5), // warna teks saran & kesan
              ),
            ),
            const SizedBox(height: 16),
            _buildFeedbackSection(profileController),
            
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  // --- [BARU] WIDGET SECTION PENGATURAN ---
  Widget _buildSettingsSection(ProfileController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D), // warna background untuk section pengaturan login sidik jari dan buta warna
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10), // warna border section pengaturan
      ),
      child: Column(
        children: [
          // Row Fingerprint
          Obx(() => ListTile(
              leading: Obx(() => Icon(
              controller.isFingerprintEnabled.value ? Icons.fingerprint : Icons.lock_outline, 
              color: controller.isFingerprintEnabled.value ? AppColors.primary : Colors.white54 // warna ikon berubah sesuai status fingerprint (aktif: warna utama, nonaktif: putih transparan)
            )),
            title: const Text("Login Sidik Jari", style: TextStyle(color: Colors.white, fontSize: 14)), // warna teks login sidik jari
            subtitle: const Text("Gunakan biometrik untuk masuk", style: TextStyle(color: Colors.white54, fontSize: 11)), // warna teks gunakan biometrik untuk masuk
            trailing: Switch(
              value: controller.isFingerprintEnabled.value,
              onChanged: (val) => controller.toggleFingerprint(val),
              activeThumbColor: AppColors.primary, // warna switch saat aktif
            ),
          )),
          const Divider(color: Colors.white10, indent: 50), // warna divider putih transparan untuk memisahkan row fingerprint dan row buta warna
          // Row Buta Warna
          Obx(() => ListTile(
            leading: const Icon(Icons.visibility_outlined, color: AppColors.primary), // warna ikon buta warna
            title: const Text("Mode Visual", style: TextStyle(color: Colors.white, fontSize: 14)), // warna teks mode visual
            subtitle: const Text("Pilihan filter buta warna", style: TextStyle(color: Colors.white54, fontSize: 11)), // warna teks pilihan filter buta warna
            trailing: DropdownButton<String>(
              value: controller.selectedColorBlindType.value,
              dropdownColor: const Color(0xFF1A1A1A), // warna background dropdown buta warna
              underline: const SizedBox(),
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold), // warna teks normal dll
              onChanged: (String? newValue) => controller.changeColorBlindType(newValue),
              items: controller.colorBlindOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          )),
        ],
      ),
    );
  }

  // --- WIDGET HEADER PROFIL (Tetap Sama) ---
  Widget _buildProfileHeader(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        children: [
          Stack(
            children: [
              Obx(() => CircleAvatar(
                radius: 36, 
                backgroundColor: AppColors.primary.withOpacity(0.2), // warna background avatar
                backgroundImage: controller.profileImageUrl.value.isNotEmpty
                    ? NetworkImage(controller.profileImageUrl.value)
                    : null,
                child: controller.profileImageUrl.value.isEmpty
                    ? Text(
                        controller.userName.value.isNotEmpty 
                            ? controller.userName.value[0].toUpperCase() 
                            : 'P',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary), // warna teks inisial nama pada avatar jika tidak ada foto profil (warna utama)
                      )
                    : null,
              )),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (!controller.isUploading.value) {
                      controller.pickAndUploadImage();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary, // warna background ikon kamera
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0B0F), width: 2),  // warna pinggiran ikon
                    ),
                    child: Obx(() => controller.isUploading.value
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14)), // warna ikon kamera (putih)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        controller.userName.value,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain), // warna teks nama pengguna
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        controller.userEmail.value,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), // warna teks email pengguna
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 28), // warna ikon edit profil
                  onPressed: () => _showEditProfileDialog(controller),
                  tooltip: 'Edit Profil',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG EDIT PROFIL & LOGOUT (Tetap Sama) ---
  void _showEditProfileDialog(ProfileController controller) {
    TextEditingController usernameCtrl = TextEditingController(text: controller.userName.value);
    TextEditingController passwordCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A), // warna background dialog edit profil
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // warna teks judul dialog edit profil
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameCtrl,
              style: const TextStyle(color: Colors.white), // warna teks input username
              decoration: const InputDecoration(
                labelText: 'Username Baru',
                labelStyle: TextStyle(color: Colors.white54), // warna label username
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)), // warna border bawah saat tidak aktif
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)), // warna border bawah saat aktif
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white), // warna teks input password
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                hintText: 'Biarkan kosong jika tidak diganti',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12), // warna placeholder text pada input password
                labelStyle: TextStyle(color: Colors.white54), // warna label password
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)), // warna border bawah saat tidak aktif
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)), // warna border bawah saat aktif
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: Colors.white54))), // warna teks batal
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black), // warna tombol simpan
            onPressed: () {
              Get.back();
              if (usernameCtrl.text.trim() != controller.userName.value && usernameCtrl.text.trim().isNotEmpty) {
                controller.changeUsername(usernameCtrl.text.trim());
              }
              if (passwordCtrl.text.trim().isNotEmpty) {
                controller.changePassword(passwordCtrl.text.trim());
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  void _showLogoutDialog(ProfileController controller) {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1A1A1A), // warna background dialog logout
      title: 'Keluar Akun',
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // warna teks keluar akun
      middleText: 'Apakah kamu yakin ingin keluar?',
      middleTextStyle: const TextStyle(color: Colors.white70), // warna teks konfirmasi logout
      radius: 12,
      textCancel: 'Batal',
      cancelTextColor: Colors.white54, // warna teks batal
      textConfirm: 'Keluar',
      confirmTextColor: Colors.white, // warna teks keluar
      buttonColor: Colors.red.shade900, // warna tombol keluar
      onConfirm: () {
        Get.back(); 
        controller.logout(); 
      },
    );
  }

  // --- GRID KOLEKSI (Tetap Sama) ---
  Widget _buildCollectionGrid(EditorController controller) {
    return Obx(() {
      if (controller.isPresetsLoading.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.primary)));
      }
      if (controller.ownedPresets.isEmpty) {
        return Container(
          height: 220, alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.style_outlined, size: 60, color: Colors.white12), // warna ikon koleksi preset kosong
            const SizedBox(height: 16),
            const Text("Koleksimu masih kosong", style: TextStyle(color: Colors.white54, fontSize: 16)), // warna teks koleksi preset kosong
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black), // warna tombol kunjungi store
              icon: const Icon(Icons.storefront), label: const Text("Kunjungi Store", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Get.toNamed(AppRoutes.PRESET_STORE),
            )
          ]),
        );
      }
      return GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: controller.ownedPresets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemBuilder: (context, index) => _buildOwnedPresetCard(controller.ownedPresets[index]),
      );
    });
  }

  // --- FEEDBACK SECTION (Tetap Sama) ---
  Widget _buildFeedbackSection(ProfileController controller) {
    return Obx(() {
      if (controller.isFeedbacksLoading.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.primary)));
      }
      final feedbacks = controller.myAllFeedbacks;
      if (feedbacks.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Kamu belum mengirimkan saran atau kesan apapun.", style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center))); // warna teks ketika belum ada feedback yang dikirimkan
      }
      return ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: feedbacks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = feedbacks[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF13151D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), // warna background dan border untuk saran dan kesan
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary), SizedBox(width: 8), Text("Masukan Terkirim", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))]), // warna ikon dan teks header untuk setiap feedback
              const SizedBox(height: 8),
              Text(item['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)), // warna teks isi feedback
            ]),
          );
        },
      );
    });
  }

  // --- PRESET CARD & TIMER BADGE (Tetap Sama) ---
  Widget _buildOwnedPresetCard(Map<String, dynamic> preset) {
    bool hasTimer = preset['expires_at'] != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13151D), borderRadius: BorderRadius.circular(16), // warna background dan border untuk setiap kartu preset yang dimiliki
        border: Border.all(color: hasTimer ? Colors.orange.withOpacity(0.5) : Colors.white10, width: hasTimer ? 1.5 : 1), // warna border kartu preset (jika ada timer, gunakan warna oranye transparan, jika tidak ada timer gunakan warna putih transparan)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 4, child: Stack(children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(preset['thumbnail_url'] ?? '', fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => Container(color: Colors.black45, child: const Icon(Icons.broken_image, color: Colors.white54, size: 40)))), // menampilkan thumbnail preset, jika gagal load tampilkan placeholder
          if (hasTimer) Positioned(top: 0, right: 0, child: PresetTimerBadge(expiresAt: preset['expires_at'])),
        ])),
        Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(preset['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), // warna teks nama preset
            const SizedBox(height: 4),
            Text('by ${preset['author'] ?? 'Admin'}', style: const TextStyle(color: Colors.white54, fontSize: 11)), // warna teks author preset
          ]),
          SizedBox(width: double.infinity, height: 32, child: OutlinedButton.icon(onPressed: () => Get.snackbar('Cara Penggunaan', 
          'Pilih foto terlebih dahulu di menu Editor.', snackPosition: SnackPosition.TOP), 
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), // warna teks dan border untuk tombol milikmu
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero), 
          icon: const Icon(Icons.check_circle_outline, size: 16), label: const Text('Milikmu', style: TextStyle(fontSize: 12, 
          fontWeight: FontWeight.bold)))),
        ]))),
      ]),
    );
  }
}

class PresetTimerBadge extends StatefulWidget {
  final String expiresAt;
  const PresetTimerBadge({super.key, required this.expiresAt});
  @override State<PresetTimerBadge> createState() => _PresetTimerBadgeState();
}
class _PresetTimerBadgeState extends State<PresetTimerBadge> {
  late Timer _timer; Duration _timeLeft = Duration.zero;
  @override void initState() { super.initState(); _calculateTimeLeft(); _timer = Timer.periodic(const Duration(seconds: 1), (timer) { if(mounted) _calculateTimeLeft(); }); }
  void _calculateTimeLeft() { final expiry = DateTime.parse(widget.expiresAt).toLocal(); final now = DateTime.now(); setState(() { _timeLeft = expiry.isAfter(now) ? expiry.difference(now) : Duration.zero; }); }
  @override void dispose() { _timer.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (_timeLeft.inSeconds <= 0) return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(8))), child: const Text('Trial Ended', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)));
    String minutes = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade800.withOpacity(0.9), borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(8))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.timer, color: Colors.white, size: 12), const SizedBox(width: 4), Text('$minutes:$seconds', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]));
  }
}