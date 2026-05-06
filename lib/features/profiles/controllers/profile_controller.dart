import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:local_auth/local_auth.dart'; // [BARU] Wajib di-import untuk verifikasi Sidik Jari
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
    loadUserData(); 
    _loadAppSettings(); 
  }

  void _loadAppSettings() {
    isFingerprintEnabled.value = authBox.get('fingerprint_enabled', defaultValue: true);
    selectedColorBlindType.value = authBox.get('color_blind_type', defaultValue: 'Normal');
  }

  // ==========================================
  // [DIUBAH] LOGIKA SAKLAR SIDIK JARI PINTAR
  // ==========================================
  Future<void> toggleFingerprint(bool value) async {
    if (value == false) {
      // 1. JIKA USER MENONAKTIFKAN FITUR
      isFingerprintEnabled.value = false;
      authBox.put('fingerprint_enabled', false);
      Get.snackbar(
        'Dinonaktifkan 🔓', 
        'Login Sidik Jari telah dimatikan.', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.blueGrey.shade900, 
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      // 2. JIKA USER INGIN MENGAKTIFKAN FITUR
      final LocalAuthentication localAuth = LocalAuthentication();
      try {
        // Cek dulu apakah HP-nya mendukung sidik jari
        bool canCheckBiometrics = await localAuth.canCheckBiometrics;
        bool isSupported = await localAuth.isDeviceSupported();

        if (!canCheckBiometrics || !isSupported) {
          Get.snackbar('Gagal', 'Perangkat ini tidak mendukung sensor biometrik.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
          return;
        }

        // Minta user memindai jarinya sebagai bukti
        bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Pindai sidik jari Anda untuk mengaktifkan fitur ini',
          biometricOnly: true,
        );

        if (didAuthenticate) {
          // Jika sidik jari cocok, nyalakan fiturnya
          isFingerprintEnabled.value = true;
          authBox.put('fingerprint_enabled', true);
          Get.snackbar(
            'Diaktifkan 🔒', 
            'Login Sidik Jari berhasil diaktifkan.', 
            snackPosition: SnackPosition.BOTTOM, 
            backgroundColor: Colors.green.shade800, 
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Jika dibatalkan atau sidik jari salah, beri tahu user (Saklar akan tetap mati otomatis)
          Get.snackbar('Dibatalkan', 'Verifikasi sidik jari gagal atau dibatalkan.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange.shade900, colorText: Colors.white);
        }
      } catch (e) {
        Get.snackbar('Error', 'Terjadi kesalahan sensor: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void changeColorBlindType(String? newValue) {
    if (newValue != null) {
      selectedColorBlindType.value = newValue;
      authBox.put('color_blind_type', newValue);
      Get.snackbar('Tampilan Diperbarui', 'Mode visual diubah ke $newValue', 
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.blueGrey, colorText: Colors.white);
    }
  }

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
      profileImageUrl.value = ''; 
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> changeUsername(String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      var userData = authBox.get(userEmail.value) ?? {};
      userData['name'] = newName;
      await authBox.put(userEmail.value, userData);
      userName.value = newName;
      
      Get.snackbar('Berhasil 🎉', 'Username diubah menjadi $newName', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (newPassword.trim().isEmpty) return;
    try {
      var userData = authBox.get(userEmail.value) ?? {};
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
      
      final response = await supabase
          .from('feedbacks') 
          .select()
          .eq('user_email', userEmail.value)
          .order('created_at', ascending: false); 
      
      final List<Map<String, dynamic>> allUserFeedbacks = List<Map<String, dynamic>>.from(response);

      myAllFeedbacks.value = allUserFeedbacks.where((feedback) {
        final String content = (feedback['content'] ?? '').toString().toLowerCase();
        return content.contains('saran') || content.contains('kesan');
      }).toList();

    } catch (e) {
      debugPrint("Gagal memuat feedback: $e");
    } finally {
      isFeedbacksLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
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
    loadUserData(); 
    try {
      Get.delete<EditorController>(force: true);
    } catch(e) {}
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}