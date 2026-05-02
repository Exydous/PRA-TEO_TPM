import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/routes/app_routes.dart';
import '../../editor/controllers/editor_controller.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ProfileController extends GetxController {
  final Box authBox = Hive.box('authBox'); 
  final supabase = Supabase.instance.client;
  
  var userName = ''.obs;
  var userEmail = ''.obs;

  var isUploading = false.obs;
  var profileImageUrl = ''.obs;

  var myAllFeedbacks = <Map<String, dynamic>>[].obs;
  var isFeedbacksLoading = false.obs;

  var isFingerprintEnabled = true.obs;
  var selectedColorBlindType = 'Normal'.obs;

  final List<String> colorBlindOptions = [
    'Normal',
    'Protanopia (Merah)',
    'Deuteranopia (Hijau)',
    'Tritanopia (Biru)',
    'Monochromacy (Total)'
  ];

  @override
  void onInit() {
    super.onInit();
    loadUserData(); // [DIUBAH] Menghilangkan underscore
    _loadAppSettings(); 
  }

  void _loadAppSettings() {
    isFingerprintEnabled.value = authBox.get('fingerprint_enabled', defaultValue: true);
    selectedColorBlindType.value = authBox.get('color_blind_type', defaultValue: 'Normal');
  }

  void toggleFingerprint(bool value) {
    isFingerprintEnabled.value = value;
    authBox.put('fingerprint_enabled', value);
  }

  void changeColorBlindType(String? newValue) {
    if (newValue != null) {
      selectedColorBlindType.value = newValue;
      authBox.put('color_blind_type', newValue);
      Get.snackbar('Tampilan Diperbarui', 'Mode visual diubah ke $newValue', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
    }
  }

  // --- [DIUBAH] Menghilangkan underscore agar bisa di-refresh dari AuthController ---
  void loadUserData() {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    
    if (currentEmail.isNotEmpty) {
      userEmail.value = currentEmail;
      
      var userData = authBox.get(currentEmail);
      if (userData != null) {
        userName.value = userData['name'] ?? 'Pengguna';
        profileImageUrl.value = userData['avatar_url'] ?? ''; 
      } else {
        userName.value = 'Pengguna';
      }

      loadMyFeedbacks();
    } else {
      userEmail.value = 'Tidak ada email';
      userName.value = 'Guest';
      profileImageUrl.value = ''; // Hapus foto profil jika logout
    }
  }

  // --- [BARU] ALAT ENKRIPSI PASSWORD ---
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // --- PERBAIKAN: GANTI NAMA KE HIVE ---
  Future<void> changeUsername(String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      // Ambil data user dari Hive
      var userData = authBox.get(userEmail.value) ?? {};
      
      // Ubah namanya dan simpan kembali ke Hive
      userData['name'] = newName;
      await authBox.put(userEmail.value, userData);
      
      // Update tampilan layar
      userName.value = newName;
      
      Get.snackbar('Berhasil 🎉', 'Username diubah menjadi $newName', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- PERBAIKAN: GANTI PASSWORD KE HIVE ---
  Future<void> changePassword(String newPassword) async {
    if (newPassword.trim().isEmpty) return;
    try {
      // Ambil data user dari Hive
      var userData = authBox.get(userEmail.value) ?? {};
      
      // Enkripsi password barunya, lalu simpan ke Hive
      userData['password'] = _hashPassword(newPassword);
      await authBox.put(userEmail.value, userData);
      
      Get.snackbar('Berhasil 🔐', 'Password berhasil diperbarui', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> loadMyFeedbacks() async {
    if (userEmail.value.isEmpty) return;
    try {
      isFeedbacksLoading.value = true;
      
      // 1. Ambil SEMUA feedback milik user ini dari Supabase (diurutkan dari yang terbaru)
      final response = await supabase
          .from('feedbacks') 
          .select()
          .eq('user_email', userEmail.value)
          .order('created_at', ascending: false); 
      
      // 2. Ubah data dari database menjadi List
      final List<Map<String, dynamic>> allUserFeedbacks = List<Map<String, dynamic>>.from(response);

      // 3. FILTERING CERDAS (Hanya masukkan ke Profil jika ada kata "saran" atau "kesan")
      myAllFeedbacks.value = allUserFeedbacks.where((feedback) {
        // Ubah teks jadi huruf kecil semua agar filternya kebal terhadap huruf kapital (Saran, SARAN, saran)
        final String content = (feedback['content'] ?? '').toString().toLowerCase();
        
        // Kembalikan nilai true jika mengandung kata "saran" ATAU "kesan"
        return content.contains('saran') || content.contains('kesan');
      }).toList();

    } catch (e) {
      debugPrint("Gagal memuat feedback: $e");
    } finally {
      isFeedbacksLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    // ... Kodingan upload image tetap sama persis ...
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Atur Foto Profil', toolbarColor: const Color(0xFF0A0B0F), toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.square),
      ],
    );

    if (croppedFile == null) return;

    isUploading.value = true;
    try {
      final file = File(croppedFile.path);
      final fileExt = image.path.split('.').last;
      final safeEmail = userEmail.value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '$safeEmail-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('avatars').upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      var userData = authBox.get(userEmail.value) ?? {};
      userData['avatar_url'] = publicUrl; 
      await authBox.put(userEmail.value, userData); 
      profileImageUrl.value = publicUrl;
    } catch (e) {} finally {
      isUploading.value = false;
    }
  }

  Future<void> logout() async {
    await authBox.delete('currentUser');
    loadUserData(); // [BARU] Kembalikan status ke Guest setelah logout
    try {
      Get.delete<EditorController>(force: true);
    } catch(e) {}
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}