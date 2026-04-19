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

  Future<void> submit() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();
    String rePassword = rePasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Peringatan', 'Email dan password tidak boleh kosong', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (isLoginMode.value) {
      await loginUser(email, password);
    } else {
      // Validasi Tambahan untuk Registrasi
      if (name.isEmpty) {
        Get.snackbar('Peringatan', 'Nama lengkap wajib diisi', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      if (password != rePassword) {
        Get.snackbar('Peringatan', 'Konfirmasi password tidak cocok', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (password.length < 6) {
        Get.snackbar('Peringatan', 'Password minimal 6 karakter', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      await registerUser(name, email, password);
    }
  }

  // --- LOGIKA REGISTRASI ---
  Future<void> registerUser(String name, String email, String password) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
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
  Future<void> loginUser(String email, String password) async {
    isLoading.value = true;
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
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
    } on AuthException catch (e) {
      Get.snackbar('❌ Login Gagal', e.message, backgroundColor: Colors.red.shade900, colorText: Colors.white);
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
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}