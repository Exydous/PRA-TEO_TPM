import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // [BARU] Import Image Cropper
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/routes/app_routes.dart';
import '../../editor/controllers/editor_controller.dart';

class ProfileController extends GetxController {
  // Panggil Kotak Rahasia Hive & Klien Supabase
  final Box authBox = Hive.box('authBox'); 
  final supabase = Supabase.instance.client;
  
  var userName = ''.obs;
  var userEmail = ''.obs;

  // Variabel untuk foto profil
  var isUploading = false.obs;
  var profileImageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // --- Mengambil nama, email, dan FOTO dari Hive ---
  void _loadUserData() {
    // 1. Cek siapa email yang sedang aktif saat ini
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    
    if (currentEmail.isNotEmpty) {
      userEmail.value = currentEmail;
      
      // 2. Ambil data lengkap berdasarkan email tersebut
      var userData = authBox.get(currentEmail);
      if (userData != null) {
        userName.value = userData['name'] ?? 'Pengguna';
        // Muat URL foto dari Hive jika sudah pernah diunggah
        profileImageUrl.value = userData['avatar_url'] ?? ''; 
      } else {
        userName.value = 'Pengguna';
      }
    } else {
      userEmail.value = 'Tidak ada email';
      userName.value = 'Guest';
    }
  }

  // --- [DIUBAH] Fungsi Ambil, Potong (Crop), & Unggah Foto ---
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    
    // 1. Pilih foto dari galeri
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    // 2. Buka layar Editor/Cropper
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      // [DIHAPUS] Baris aspectRatio: const CropAspectRatio(...) dihapus agar tidak terkunci paksa

      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Foto Profil',
          toolbarColor: const Color(0xFF0A0B0F), 
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square, // Muncul pertama kali sebagai kotak
          lockAspectRatio: false, // [DIUBAH] Jadikan 'false' agar ujung kotak bisa ditarik/diatur dengan jari
          hideBottomControls: false, 
        ),
        IOSUiSettings(
          title: 'Atur Foto Profil',
          aspectRatioLockEnabled: false, // [DIUBAH] Buka kunci rasio untuk iOS
          resetButtonHidden: false,
        ),
      ],
    );

    // Jika pengguna batal memotong dan menekan tombol kembali
    if (croppedFile == null) return;

    isUploading.value = true;
    try {
      // [PENTING] Gunakan file hasil CROP, bukan file asli
      final file = File(croppedFile.path);
      final fileExt = image.path.split('.').last;
      
      // Bersihkan email dari karakter aneh untuk dijadikan nama file
      final safeEmail = userEmail.value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '$safeEmail-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // A. Unggah file fisik ke Supabase Storage (Bucket: 'avatars')
      await supabase.storage.from('avatars').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // B. Ambil Link/URL Publik dari foto yang baru diunggah
      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // C. Simpan URL tersebut ke dalam Hive agar tidak hilang saat aplikasi ditutup
      var userData = authBox.get(userEmail.value) ?? {};
      userData['avatar_url'] = publicUrl; 
      await authBox.put(userEmail.value, userData); // Update data di Hive

      // D. Update tampilan di layar
      profileImageUrl.value = publicUrl;
      
      Get.snackbar(
        "Sukses", "Foto profil berhasil diperbarui!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error", "Gagal mengunggah foto: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUploading.value = false;
    }
  }

  // --- Fungsi Logout Lokal ---
  Future<void> logout() async {
    // Hapus sesi aktif dari Hive (Logout Lokal)
    await authBox.delete('currentUser');
    
    // Bersihkan memori draft editor
    try {
      Get.delete<DraftController>(force: true); 
    } catch(e) {}
    Get.delete<EditorController>(force: true);

    Get.offAllNamed(AppRoutes.LOGIN);
  }
}