import 'dart:convert'; // Untuk utf8.encode
import 'package:crypto/crypto.dart'; // Untuk SHA-256
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // [BARU] Import Hive
import '../../../core/routes/app_routes.dart';

class AuthController extends GetxController {
  // [BARU] Panggil Kotak Rahasia Hive untuk sistem Auth Lokal
  final Box authBox = Hive.box('authBox'); 
  
  var isLoading = false.obs;
  var isLoginMode = true.obs; // Toggle antara Login & Register

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    
    // [BARU] Panggil fungsi intip saat layar Auth pertama kali dibuka
    intipIsiHive(); 
    
    _checkExistingSession();
  }

  // [DIUBAH] Cek sesi sekarang menggunakan Hive
  void _checkExistingSession() {
    if (authBox.containsKey('currentUser')) {
      // Pastikan menggunakan AppRoutes.MAIN (atau sesuaikan dengan file app_routes.dart)
      Future.delayed(Duration.zero, () => Get.offAllNamed(AppRoutes.MAIN));
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

  // --- 1. MESIN VALIDASI PASSWORD (TETAP SAMA) ---
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

  // --- 2. MESIN ENKRIPSI SHA-256 (TETAP SAMA) ---
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

  // --- [DIUBAH] LOGIKA REGISTRASI LOKAL HIVE ---
  Future<void> registerUser(String name, String email, String rawPassword) async {
    isLoading.value = true;
    try {
      // 1. Cek apakah email sudah terdaftar di HP
      if (authBox.containsKey(email)) {
        Get.snackbar('❌ Gagal', 'Email ini sudah terdaftar di perangkat ini.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
        return;
      }

      // 2. ENKRIPSI PASSWORD SEBELUM DISIMPAN
      String securedPassword = hashPassword(rawPassword);

      // 3. Simpan data (termasuk nama) ke Hive dengan format Map JSON
      await authBox.put(email, {
        'name': name,
        'password': securedPassword,
      });

      // [BARU] Panggil fungsi intip untuk melihat data yang baru saja masuk
      intipIsiHive();

      Get.snackbar(
        '✅ Berhasil', 
        'Akun $name telah dibuat. Silakan login.', 
        backgroundColor: Colors.green.shade800, 
        colorText: Colors.white
      );
      
      // Otomatis pindah ke mode login setelah sukses daftar
      isLoginMode.value = true;
      
    } catch (e) {
      Get.snackbar('❌ Gagal', 'Terjadi kesalahan: $e', backgroundColor: Colors.red.shade900, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- [DIUBAH] LOGIKA LOGIN LOKAL HIVE ---
  Future<void> loginUser(String email, String rawPassword) async {
    isLoading.value = true;
    try {
      // 1. Ambil data akun dari memori berdasarkan email
      var userData = authBox.get(email);

      // Cek jika akun tidak ditemukan
      if (userData == null) {
        Get.snackbar('❌ Login Gagal', 'Email atau Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
        return;
      }

      // 2. ENKRIPSI INPUT USER UNTUK DICOCOKKAN DENGAN DATABASE LOKAL
      String securedPassword = hashPassword(rawPassword);

      // 3. Cocokkan Hash Password
      if (userData['password'] == securedPassword) {
        // Jika berhasil, simpan ID email ke 'currentUser' sebagai penanda sesi aktif
        await authBox.put('currentUser', email);

        // [BARU] Intip isi Hive untuk melihat sesi currentUser
        intipIsiHive();

        emailController.clear();
        passwordController.clear();
        
        Get.offAllNamed(AppRoutes.MAIN);
        Get.snackbar(
          '👋 Selamat Datang', 
          'Login berhasil!', 
          backgroundColor: Colors.blueGrey.shade900, 
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar('❌ Login Gagal', 'Email atau Password salah.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('❌ Error', 'Terjadi kesalahan sistem.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- [DIUBAH] LOGIKA LOGOUT LOKAL HIVE ---
  Future<void> logoutUser() async {
    // Cukup hapus kunci sesi aktifnya, datanya sendiri tetap aman di Hive
    await authBox.delete('currentUser');
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  // --- [BARU] Fungsi Tambahan Untuk Mengambil Nama di Tab Profile Nanti ---
  String getActiveUserName() {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    if (currentEmail.isNotEmpty) {
      var userData = authBox.get(currentEmail);
      if (userData != null) {
        return userData['name'] ?? 'User';
      }
    }
    return 'User';
  }

  // --- [BARU] FUNGSI DEBUG UNTUK MELIHAT ISI HIVE ---
  void intipIsiHive() {
    print('========== ISI KOTAK HIVE ==========');
    if (authBox.isEmpty) {
      print('Kotak kosong! Belum ada user terdaftar.');
    } else {
      for (var key in authBox.keys) {
        print('🔑 Key : $key');
        print('📦 Data: ${authBox.get(key)}');
        print('------------------------------------');
      }
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