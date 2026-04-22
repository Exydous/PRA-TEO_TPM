import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // [BARU] Import Hive
import '../../../core/routes/app_routes.dart';
import '../../editor/controllers/editor_controller.dart';

class ProfileController extends GetxController {
  // [BARU] Panggil Kotak Rahasia Hive
  final Box authBox = Hive.box('authBox'); 
  
  var userName = ''.obs;
  var userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // --- [DIUBAH] Mengambil nama dan email dari Hive ---
  void _loadUserData() {
    // 1. Cek siapa email yang sedang aktif saat ini
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    
    if (currentEmail.isNotEmpty) {
      userEmail.value = currentEmail;
      
      // 2. Ambil data lengkap (termasuk nama) berdasarkan email tersebut
      var userData = authBox.get(currentEmail);
      if (userData != null) {
        userName.value = userData['name'] ?? 'Pengguna';
      } else {
        userName.value = 'Pengguna';
      }
    } else {
      userEmail.value = 'Tidak ada email';
      userName.value = 'Guest';
    }
  }

  // --- [DIUBAH] Fungsi Logout Lokal ---
  Future<void> logout() async {
    // Hapus sesi aktif dari Hive (Logout Lokal)
    await authBox.delete('currentUser');
    
    // Hapus controller dari memori agar data lama hilang total
    // (Abaikan jika DraftController muncul garis merah, bisa dihapus baris ini jika tidak dipakai)
    try {
      Get.delete<DraftController>(force: true); 
    } catch(e) {}
    Get.delete<EditorController>(force: true);

    Get.offAllNamed(AppRoutes.LOGIN);
  }
}