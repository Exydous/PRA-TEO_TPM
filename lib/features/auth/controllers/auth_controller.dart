import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/routes/app_routes.dart';
// [BARU] Import ProfileController untuk memerintahkan Refresh Data
import '../../profiles/controllers/profile_controller.dart'; 

class AuthController extends GetxController {
  final Box authBox = Hive.box('authBox'); 
  final LocalAuthentication localAuth = LocalAuthentication(); 
  
  var isLoading = false.obs;
  var isLoginMode = true.obs;
  var isBiometricSupported = false.obs;
  var hasSavedUser = false.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    intipIsiHive(); 
    _checkExistingSession();
    _checkBiometricAndUser(); 
  }

  Future<void> _checkBiometricAndUser() async {
    // --- [PERBAIKAN SAKLAR FINGERPRINT] ---
    // Cek apakah user mematikan fitur biometrik di profil
    bool isFingerprintEnabled = authBox.get('fingerprint_enabled', defaultValue: true);
    if (!isFingerprintEnabled) {
      isBiometricSupported.value = false; 
      return; // Langsung keluar, tombol biometrik di halaman login tidak akan muncul
    }

    String lastEmail = authBox.get('lastEmail', defaultValue: '');
    hasSavedUser.value = lastEmail.isNotEmpty;

    try {
      bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      bool isSupported = await localAuth.isDeviceSupported();
      isBiometricSupported.value = canCheckBiometrics && isSupported;
    } catch (e) {
      isBiometricSupported.value = false;
    }
  }

  Future<void> loginWithBiometric() async {
    String lastEmail = authBox.get('lastEmail', defaultValue: '');

    if (lastEmail.isEmpty) {
      Get.snackbar('Info', 'Silakan login manual dulu sekali.', backgroundColor: Colors.blueGrey);
      return;
    }

    try {
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke aplikasi',
        biometricOnly: true, // Diupdate agar tidak ada warning error
      );

      if (didAuthenticate) {
        await authBox.put('currentUser', lastEmail);

        // --- [PERBAIKAN PROFIL GUEST] ---
        // Suruh ProfileController muat ulang data sesuai akun yang baru login
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadUserData();
        }

        Get.offAllNamed(AppRoutes.MAIN);
        Get.snackbar('Selamat Datang Kembali', 'Login Biometrik Berhasil!', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Autentikasi biometrik gagal: $e');
    }
  }

  void _checkExistingSession() {
    if (authBox.containsKey('currentUser')) {
      Future.delayed(Duration.zero, () => Get.offAllNamed(AppRoutes.MAIN));
    }
  }

  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    rePasswordController.clear();
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> submit() async {
    String email = emailController.text.trim();
    String rawPassword = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || rawPassword.isEmpty) {
      Get.snackbar('Peringatan', 'Email dan password tidak boleh kosong', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (isLoginMode.value) {
      await loginUser(email, rawPassword);
    } else {
      await registerUser(name, email, rawPassword);
    }
  }

  Future<void> registerUser(String name, String email, String rawPassword) async {
    isLoading.value = true;
    try {
      if (authBox.containsKey(email)) {
        Get.snackbar('❌ Gagal', 'Email sudah terdaftar.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
        return;
      }
      String securedPassword = hashPassword(rawPassword);
      await authBox.put(email, {'name': name, 'password': securedPassword});
      isLoginMode.value = true;
      Get.snackbar('✅ Berhasil', 'Akun telah dibuat.', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser(String email, String rawPassword) async {
    isLoading.value = true;
    try {
      var userData = authBox.get(email);

      if (userData == null) {
        Get.snackbar('❌ Login Gagal', 'Email/Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
        return;
      }

      String securedPassword = hashPassword(rawPassword);

      if (userData['password'] == securedPassword) {
        await authBox.put('currentUser', email);
        await authBox.put('lastEmail', email); 

        // --- [PERBAIKAN PROFIL GUEST] ---
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadUserData();
        }

        Get.offAllNamed(AppRoutes.MAIN);
      } else {
        Get.snackbar('❌ Login Gagal', 'Email/Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
      }
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutUser() async {
    await authBox.delete('currentUser');
    
    // Kembalikan ke Guest
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().loadUserData();
    }
    
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  void intipIsiHive() {
    print('========== ISI KOTAK HIVE ==========');
    for (var key in authBox.keys) {
      print('🔑 Key : $key | 📦 Data: ${authBox.get(key)}');
    }
    print('====================================');
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.onClose();
  }
}