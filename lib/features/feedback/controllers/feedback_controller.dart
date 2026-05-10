import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// [PENTING] Tambahkan import ProfileController sesuai dengan letak folder Capt.
// Sesuaikan path ini jika ada error garis merah.
import '../../profiles/controllers/profile_controller.dart'; 

class FeedbackController extends GetxController {
  final supabase = Supabase.instance.client;
  final Box authBox = Hive.box('authBox');

  var feedbacks = <Map<String, dynamic>>[].obs;
  var replies = <Map<String, dynamic>>[].obs;
  
  var isLoading = false.obs;
  var isRepliesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFeedbacks();
  }

  // --- 1. AMBIL SEMUA POSTINGAN UTAMA ---
  Future<void> fetchFeedbacks() async {
    isLoading.value = true;
    try {
      final response = await supabase
          .from('feedbacks')
          .select()
          .order('created_at', ascending: false);
      feedbacks.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch feedbacks");
    } finally {
      isLoading.value = false;
    }
  }

  // --- 2. KIRIM POSTINGAN UTAMA ---
  Future<void> postFeedback(String content) async {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    if (currentEmail.isEmpty) {
      Get.snackbar('Gagal', 'Kamu harus login untuk memposting.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
      return;
    }

    var userData = authBox.get(currentEmail);
    String userName = userData?['name'] ?? 'Anonim';

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      await supabase.from('feedbacks').insert({
        'user_email': currentEmail,
        'user_name': userName,
        'content': content,
      });
      
      Get.back(); // Tutup loading
      Get.back(); // Tutup bottom sheet
      
      fetchFeedbacks(); // Refresh daftar komunitas
      
      // --- [BARU] PELATUK REFRESH PROFIL ---
      // Jika controller profil sedang aktif, suruh dia ambil data baru dari Supabase
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().loadMyFeedbacks();
      }

      Get.snackbar('Berhasil', 'Pesanmu telah dikirim ke komunitas!', backgroundColor: Colors.green.shade800, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Gagal mengirim pesan', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- 3. AMBIL BALASAN UNTUK POSTINGAN TERTENTU ---
  Future<void> fetchReplies(String feedbackId) async {
    isRepliesLoading.value = true;
    try {
      final response = await supabase
          .from('feedback_replies')
          .select()
          .eq('feedback_id', feedbackId)
          .order('created_at', ascending: true); // Balasan terlama di atas
      replies.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch replies");
    } finally {
      isRepliesLoading.value = false;
    }
  }

  // --- 4. KIRIM BALASAN (KOMENTAR) ---
  Future<void> postReply(String feedbackId, String content) async {
    String currentEmail = authBox.get('currentUser', defaultValue: '');
    if (currentEmail.isEmpty) {
      Get.snackbar('Gagal', 'Kamu harus login untuk membalas.', backgroundColor: Colors.red.shade900, colorText: Colors.white);
      return;
    }

    var userData = authBox.get(currentEmail);
    String userName = userData?['name'] ?? 'Anonim';

    try {
      await supabase.from('feedback_replies').insert({
        'feedback_id': feedbackId,
        'user_email': currentEmail,
        'user_name': userName,
        'content': content,
      });
      fetchReplies(feedbackId); // Langsung refresh balasan di layar
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim balasan', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  String? getUserPhoto(String? email) {
    if (email == null || email.isEmpty) return null;
    
    // Ambil data user dari Hive berdasarkan email
    var userData = authBox.get(email);
    
    // Jika data ada dan photoUrl tidak kosong, kembalikan url-nya
    if (userData != null && userData['avatar_url'] != null && userData['avatar_url'].toString().isNotEmpty) {
      return userData['avatar_url'];
    }
    return null;
  }
}