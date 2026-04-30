import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/routes/app_routes.dart';
import '../../editor/controllers/editor_controller.dart';

class ProfileController extends GetxController {
  final Box authBox = Hive.box('authBox'); 
  final supabase = Supabase.instance.client;
  
  var userName = ''.obs;
  var userEmail = ''.obs;

  var isUploading = false.obs;
  var profileImageUrl = ''.obs;

  var myAllFeedbacks = <Map<String, dynamic>>[].obs;
  var isFeedbacksLoading = false.obs;

  // --- [BARU] VARIABEL PENGATURAN ---
  var isFingerprintEnabled = true.obs;
  var selectedColorBlindType = 'Normal'.obs;

  // Daftar pilihan buta warna untuk Dropdown
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
    _loadUserData();
    _loadAppSettings(); // Muat pengaturan fingerprint & buta warna
  }

  // --- [BARU] LOGIKA PENGATURAN ---
  void _loadAppSettings() {
    // Ambil dari Hive, jika kosong default ke true/Normal
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

  // --- LOGIKA PROFIL LAMA ---
  void _loadUserData() {
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
    }
  }

  Future<void> changeUsername(String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      await supabase.auth.updateUser(UserAttributes(data: {'username': newName}));
      
      var userData = authBox.get(userEmail.value) ?? {};
      userData['name'] = newName;
      await authBox.put(userEmail.value, userData);

      userName.value = newName;
      Get.snackbar('Berhasil 🎉', 'Username diubah menjadi $newName', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak dapat mengubah username: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (newPassword.trim().isEmpty) return;
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar('Berhasil 🔐', 'Password berhasil diperbarui', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak dapat memperbarui password: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
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
          .or('content.ilike.%saran%,content.ilike.%kesan%'); 
      
      myAllFeedbacks.value = List<Map<String, dynamic>>.from(response);
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
        AndroidUiSettings(
          toolbarTitle: 'Atur Foto Profil',
          toolbarColor: const Color(0xFF0A0B0F), 
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
      ],
    );

    if (croppedFile == null) return;

    isUploading.value = true;
    try {
      final file = File(croppedFile.path);
      final fileExt = image.path.split('.').last;
      final safeEmail = userEmail.value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '$safeEmail-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('avatars').upload(fileName, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      var userData = authBox.get(userEmail.value) ?? {};
      userData['avatar_url'] = publicUrl; 
      await authBox.put(userEmail.value, userData); 

      profileImageUrl.value = publicUrl;
    } catch (e) {
      Get.snackbar("Error", "Gagal mengunggah foto: $e", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> logout() async {
    await authBox.delete('currentUser');
    try {
      Get.delete<EditorController>(force: true);
    } catch(e) {}
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}