import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart'; // [BARU] Import Biometrik
import '../../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final Box authBox = Hive.box('authBox'); 
  final LocalAuthentication localAuth = LocalAuthentication(); // [BARU] Inisialisasi Biometrik
  
  var isLoading = false.obs;
  var isLoginMode = true.obs;

  // [BARU] Status Biometrik
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
    _checkBiometricAndUser(); // [BARU] Cek kesiapan sensor saat start
  }

  // --- [BARU] Fungsi Inisialisasi Biometrik ---
  Future<void> _checkBiometricAndUser() async {
    // Cek apakah ada email terakhir yang tersimpan di Hive
    String lastEmail = authBox.get('lastEmail', defaultValue: '');
    hasSavedUser.value = lastEmail.isNotEmpty;

    // Cek apakah HP ini mendukung sidik jari/Face ID
    try {
      bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      bool isSupported = await localAuth.isDeviceSupported();
      isBiometricSupported.value = canCheckBiometrics && isSupported;
    } catch (e) {
      isBiometricSupported.value = false;
    }
  }

  // --- [BARU] Logika Login Jalur Pintas (Biometrik) ---
  Future<void> loginWithBiometric() async {
    // 1. Cek dulu siapa email terakhir yang login di HP ini
    String lastEmail = authBox.get('lastEmail', defaultValue: '');

    if (lastEmail.isEmpty) {
      Get.snackbar('Info', 'Silakan login manual dulu sekali agar sidik jari bisa didaftarkan.', 
          backgroundColor: Colors.blueGrey);
      return;
    }

    try {
      // 2. Munculkan Pop-up Sidik Jari/Face ID
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke aplikasi',
        biometricOnly: true, // Paksa pakai biometrik, bukan PIN angka HP
      );

      if (didAuthenticate) {
        // 3. Jika jari cocok, buat sesi aktif baru untuk email terakhir
        await authBox.put('currentUser', lastEmail);

        Get.offAllNamed(AppRoutes.MAIN);
        Get.snackbar(
          'Selamat Datang Kembali', 
          'Login Biometrik Berhasil!',
          backgroundColor: Colors.blueGrey.shade900, 
          colorText: Colors.white,
        );
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
      // (Logika registrasi tetap sama seperti kodinganmu sebelumnya)
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

      await authBox.put(email, {
        'name': name,
        'password': securedPassword,
      });

      isLoginMode.value = true;
      Get.snackbar('✅ Berhasil', 'Akun telah dibuat.', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('❌ Gagal', 'Kesalahan: $e');
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
        // [PENTING] Simpan sesi aktif DAN simpan email sebagai "Pengguna Terakhir"
        await authBox.put('currentUser', email);
        await authBox.put('lastEmail', email); // [BARU] Untuk pemicu biometrik nanti

        Get.offAllNamed(AppRoutes.MAIN);
      } else {
        Get.snackbar('❌ Login Gagal', 'Email/Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('❌ Error', 'Kesalahan sistem.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutUser() async {
    await authBox.delete('currentUser');
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