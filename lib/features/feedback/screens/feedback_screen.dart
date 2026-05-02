import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feedback_controller.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  // --- WIDGET PEMBANTU UNTUK FOTO PROFIL ---
  Widget _buildProfileAvatar(FeedbackController controller, Map<String, dynamic> post) {
    String? photoUrl = controller.getUserPhoto(post['user_email']);
    String initial = post['user_name']?[0].toUpperCase() ?? 'U';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.blueAccent,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.blueAccent,
        child: Text(initial, style: const TextStyle(color: Colors.white)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final FeedbackController controller = Get.put(FeedbackController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0F),
        title: const Text('Komunitas & Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.feedbacks.isEmpty) {
          return const Center(child: Text("Belum ada diskusi. Jadilah yang pertama!", style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.feedbacks.length,
          itemBuilder: (context, index) {
            final post = controller.feedbacks[index];
            return Card(
              color: const Color(0xFF1A1C24),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                
                // --- PANGGIL WIDGET FOTO DI SINI ---
                leading: _buildProfileAvatar(controller, post),
                
                title: Text(post['user_name'] ?? 'Anonim', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(post['content'] ?? '', style: const TextStyle(color: Colors.white70)),
                ),
                trailing: const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 20),
                onTap: () => _showRepliesBottomSheet(context, controller, post),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Buat Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showCreatePostDialog(context, controller),
      ),
    );
  }

  // --- DIALOG BUAT POSTINGAN BARU ---
  void _showCreatePostDialog(BuildContext context, FeedbackController controller) {
    final TextEditingController textCtrl = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Diskusi Baru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan, saran, atau temuan bug...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (textCtrl.text.trim().isNotEmpty) {
                    controller.postFeedback(textCtrl.text.trim());
                  }
                },
                child: const Text('Posting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // --- BOTTOM SHEET UNTUK MELIHAT & MEMBALAS KOMENTAR ---
  void _showRepliesBottomSheet(BuildContext context, FeedbackController controller, Map<String, dynamic> post) {
    controller.fetchReplies(post['id']); // Load balasan saat sheet dibuka
    final TextEditingController replyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13151D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Naik saat keyboard muncul
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75, // Tinggi sheet 75% layar
            child: Column(
              children: [
                // Header (Postingan Asli)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // --- PANGGIL WIDGET FOTO DI SINI ---
                          _buildProfileAvatar(controller, post),
                          const SizedBox(width: 12),
                          Text(post['user_name'] ?? 'Anonim', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    ],
                  ),
                ),
                // List Balasan
                Expanded(
                  child: Obx(() {
                    if (controller.isRepliesLoading.value) return const Center(child: CircularProgressIndicator());
                    if (controller.replies.isEmpty) return const Center(child: Text('Belum ada balasan.', style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.replies.length,
                      itemBuilder: (context, index) {
                        final reply = controller.replies[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, left: 24.0), // Di-indent ke kanan agar terlihat seperti balasan
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF1A1C24), borderRadius: BorderRadius.circular(12)),
                            
                            // --- FOTO PROFIL UNTUK BALASAN ---
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto Profil Balasan (Ukurannya diperkecil)
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: _buildProfileAvatar(controller, reply),
                                ),
                                const SizedBox(width: 10),
                                
                                // Teks Nama & Komentar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reply['user_name'] ?? 'Anonim', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(reply['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                // Kolom Input Balasan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Color(0xFF0A0B0F), border: Border(top: BorderSide(color: Colors.white12))),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: replyCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Tulis balasan...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF1A1C24),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          onPressed: () {
                            if (replyCtrl.text.trim().isNotEmpty) {
                              controller.postReply(post['id'], replyCtrl.text.trim());
                              replyCtrl.clear(); // Kosongkan textfield setelah kirim
                            }
                          },
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}