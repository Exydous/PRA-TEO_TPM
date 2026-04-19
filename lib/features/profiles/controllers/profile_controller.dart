import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_routes.dart';
import '../../editor/controllers/editor_controller.dart';

class ProfileController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  
  var userName = ''.obs;
  var userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  // Mengambil nama dan email dari sesi Supabase yang sedang aktif
  void _loadUserData() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? 'Tidak ada email';
      // Mengambil nama dari metadata yang kita simpan saat register tadi
      userName.value = user.userMetadata?['display_name'] ?? 'Pengguna';
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
    
    // Hapus controller dari memori agar data lama hilang total
    Get.delete<DraftController>(force: true);
    Get.delete<EditorController>(force: true);

    Get.offAllNamed(AppRoutes.LOGIN);
  }
}