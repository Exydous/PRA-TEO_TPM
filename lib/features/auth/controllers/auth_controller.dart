import 'dart:convert'; // Untuk utf8.encode
import 'package:crypto/crypto.dart'; // Untuk SHA-256
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  
  var isLoading = false.obs;
  var isLoginMode = true.obs; // Toggle antara Login & Register

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  // Cek jika user tidak sengaja menutup aplikasi, tidak perlu login ulang
  void _checkExistingSession() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      Future.delayed(Duration.zero, () => Get.offAllNamed('/main'));
    }
  }

  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    // Bersihkan field saat pindah mode
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    rePasswordController.clear();
  }

  // --- 1. MESIN VALIDASI PASSWORD ---
  String? validatePassword(String password) {
    if (password.length < 8) {
      return "Password minimal 8 karakter";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password harus memiliki minimal 1 huruf kapital";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password harus memiliki minimal 1 angka";
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return "Password harus memiliki minimal 1 karakter spesial/bebas";
    }
    return null; // Return null berarti password lolos semua ujian
  }

  // --- 2. MESIN ENKRIPSI SHA-256 ---
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Ubah teks asli menjadi byte
    var digest = sha256.convert(bytes); // Proses enkripsi SHA-256
    return digest.toString(); // Hasilkan string acak
  }

  Future<void> submit() async {
    String email = emailController.text.trim();
    String rawPassword = passwordController.text.trim();
    String name = nameController.text.trim();
    String rePassword = rePasswordController.text.trim();

    if (email.isEmpty || rawPassword.isEmpty) {
      Get.snackbar('Peringatan', 'Email dan password tidak boleh kosong', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (isLoginMode.value) {
      await loginUser(email, rawPassword);
    } else {
      // Validasi Tambahan untuk Registrasi
      if (name.isEmpty) {
        Get.snackbar('Peringatan', 'Nama lengkap wajib diisi', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      if (rawPassword != rePassword) {
        Get.snackbar('Peringatan', 'Konfirmasi password tidak cocok', backgroundColor: Colors.red.shade900, colorText: Colors.white);
        return;
      }
      
      // Pengecekan Syarat Password Kuat
      String? passwordError = validatePassword(rawPassword);
      if (passwordError != null) {
        Get.snackbar('Password Lemah', passwordError, backgroundColor: Colors.orange.shade900, colorText: Colors.white);
        return;
      }

      await registerUser(name, email, rawPassword);
    }
  }

  // --- LOGIKA REGISTRASI ---
  Future<void> registerUser(String name, String email, String rawPassword) async {
    isLoading.value = true;
    try {
      // ENKRIPSI PASSWORD SEBELUM DIKIRIM
      String securedPassword = hashPassword(rawPassword);

      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: securedPassword, // Kirim password yang sudah di-hash
        data: {'display_name': name},
      );

      if (res.user != null) {
        Get.snackbar(
          '✅ Berhasil', 
          'Akun $name telah dibuat. Silakan login.', 
          backgroundColor: Colors.green.shade800, 
          colorText: Colors.white
        );
        // Otomatis pindah ke mode login setelah sukses daftar
        isLoginMode.value = true;
      }
    } on AuthException catch (e) {
      Get.snackbar('❌ Gagal', e.message, backgroundColor: Colors.red.shade900, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- LOGIKA LOGIN ---
  Future<void> loginUser(String email, String rawPassword) async {
    isLoading.value = true;
    try {
      // ENKRIPSI INPUT USER UNTUK DICOCOKKAN DENGAN DATABASE
      String securedPassword = hashPassword(rawPassword);

      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: securedPassword, // Kirim password yang sudah di-hash
      );

      if (res.user != null) {
        emailController.clear();
        passwordController.clear();
        
        Get.offAllNamed('/main');
        Get.snackbar(
          '👋 Selamat Datang', 
          'Login berhasil!', 
          backgroundColor: Colors.blueGrey.shade900, 
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on AuthException {
      // Pesan error diubah menjadi lebih aman
      Get.snackbar('❌ Login Gagal', 'Email atau Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('❌ Error', 'Terjadi kesalahan sistem.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- LOGIKA LOGOUT ---
  Future<void> logoutUser() async {
    await supabase.auth.signOut();
    Get.offAllNamed(AppRoutes.LOGIN);
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