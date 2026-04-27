import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memanggil AuthController untuk logika Supabase & Biometrik
    final AuthController controller = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.black, // Mengikuti tema gelap
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // Obx membungkus Column agar UI bisa berubah (Login <-> Register)
            child: Obx(() => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo atau Judul Aplikasi
                const Icon(
                  Icons.camera_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pro-Editor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // Teks deskripsi berubah tergantung mode
                  controller.isLoginMode.value 
                      ? 'Masuk untuk melanjutkan editanmu.'
                      : 'Daftar sekarang dan simpan karyamu di Cloud.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // --- 1. INPUT NAMA (Hanya muncul saat DAFTAR) ---
                if (!controller.isLoginMode.value) ...[
                  TextField(
                    controller: controller.nameController,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'First and last name', 
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- 2. INPUT EMAIL (Selalu muncul) ---
                TextField(
                  controller: controller.emailController, 
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- 3. INPUT PASSWORD (Selalu muncul) ---
                TextField(
                  controller: controller.passwordController, 
                  obscureText: true, 
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                
                // Jarak dinamis, jika mode daftar beri jarak 16, jika login 24
                SizedBox(height: controller.isLoginMode.value ? 24 : 16),

                // --- 4. INPUT RE-ENTER PASSWORD (Hanya muncul saat DAFTAR) ---
                if (!controller.isLoginMode.value) ...[
                  TextField(
                    controller: controller.rePasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      labelText: 'Re-enter password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- TOMBOL SUBMIT (Login / Register) ---
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black, 
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          )
                        : Text(
                            controller.isLoginMode.value ? 'LOGIN' : 'DAFTAR',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- FITUR TOGGLE PINDAH MODE Login <-> Register ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.isLoginMode.value ? "Belum punya akun? " : "Sudah punya akun? ",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: controller.toggleMode,
                      child: Text(
                        controller.isLoginMode.value ? "Daftar di sini" : "Masuk di sini",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // --- TOMBOL BIOMETRIK (Pintar) ---
                // Hanya muncul di mode LOGIN, JIKA HP mendukung, DAN user pernah login
                if (controller.isLoginMode.value && 
                    controller.isBiometricSupported.value && 
                    controller.hasSavedUser.value) ...[
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('ATAU MASUK CEPAT', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: controller.loginWithBiometric, // Panggil fungsi di AuthController
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text(
                      'Sentuh Sensor Sidik Jari',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ]
              ],
            )),
          ),
        ),
      ),
    );
  }
}