import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/color_match_controller.dart';

class ColorMatchScreen extends StatelessWidget {
  const ColorMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftarkan controller secara langsung untuk layar ini
    final controller = Get.put(ColorMatchController());

    return Scaffold(
      // 1. LATAR BELAKANG SANGAT GELAP
      backgroundColor: const Color(0xFF0A0B0F), 
      appBar: AppBar(
        // 2. JUDUL AppBar TENGAH pudar
        backgroundColor: const Color(0xFF0A0B0F),
        title: const Text(
          'Tebak Warna', 
          style: TextStyle(color: Colors.white60, fontSize: 16)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white60),
        elevation: 0,
      ),
      body: Obx(() {
        switch (controller.currentState.value) {
          case GameState.menu: return _buildMenu(controller);
          case GameState.leaderboard: return _buildLeaderboard(controller);
          case GameState.memorize: return _buildMemorize(controller);
          case GameState.guess: return _buildGuess(controller); // Ini yang kita ubah total
          case GameState.result: return _buildResult(controller);
          case GameState.finalScore: return _buildFinalScore(controller);
        }
      }),
    );
  }

  // --- HELPER WIDGETS ---
  // jangan dihapus

  // // Tombol untuk Navigasi Paling Bawah
  // Widget _mainToolButton({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(icon, color: isActive ? const Color(0xFF4FC3F7) : Colors.grey, size: 24),
  //         const SizedBox(height: 4),
  //         Text(label, style: TextStyle(color: isActive ? const Color(0xFF4FC3F7) : Colors.grey, fontSize: 12)),
  //       ],
  //     ),
  //   );
  // }

  // Helper untuk Slider Horizontal ala target
  Widget _buildHorizontalSliderRow(String label, RxDouble rxVal, double min, double max, Color thumbColor, double step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: thumbColor,
                inactiveTrackColor: Colors.white12,
                thumbColor: thumbColor,
                overlayColor: thumbColor.withOpacity(0.14),
              ),
              child: Slider(
                value: rxVal.value,
                min: min,
                max: max,
                onChanged: (val) {
                  // Tambahkan langkah (step) jika diminta
                  if (step > 0) {
                    rxVal.value = (val / step).round() * step;
                  } else {
                    rxVal.value = val;
                  }
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),            child: Text(
              "${rxVal.value.toInt()}", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
        ],
      ),
    );
  }

  // jangan dihapus
  // // Helper untuk Slider Input Teks
  // Widget _buildSliderTextField(RxDouble rxVal, String suffix) {
  //   return Container(
  //     width: 45,
  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  //     decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
  //     child: Text(
  //       '${rxVal.value.toInt()}$suffix',
  //       textAlign: TextAlign.right,
  //       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //     ),
  //   );
  // }

  // --- LAYAR 1: MENU UTAMA ---
  Widget _buildMenu(ColorMatchController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette, size: 80, color: Color(0xFF4FC3F7)),
          const SizedBox(height: 20),
          const Text("COLOR MATCH", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("GUESS THE COLOR IF YOU CAN!", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 20)),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: const Color(0xFF4FC3F7)
            ),
            onPressed: controller.startSoloGame,
            child: const Text("START GAME", style: TextStyle(fontSize: 16, color: Colors.black87)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            onPressed: () => controller.currentState.value = GameState.leaderboard,
            child: const Text("LEADERBOARD"),
          ),
        ],
      ),
    );
  }

  // --- LAYAR 2: LEADERBOARD ---
  Widget _buildLeaderboard(ColorMatchController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TOP EDITOR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          ...controller.leaderboardData.map((data) => ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(data['name']!, style: const TextStyle(color: Colors.white)),
            trailing: Text(data['score']!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          )),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: controller.backToMenu, child: const Text("Kembali"))
        ],
      ),
    );
  }

  // --- LAYAR 3: MENGINGAT WARNA (5 DETIK) ---
  Widget _buildMemorize(ColorMatchController controller) {
    Color targetColor = HSLColor.fromAHSL(1.0, controller.targetHue.value, controller.targetSat.value / 100, controller.targetLight.value / 100).toColor();
    
    return Container(
      width: double.infinity,
      color: targetColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text("ROUNDS ${controller.round.value}/4", style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 10),
                const Text("REMEMBER THE COLOR", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("${controller.countdown.value}", style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LAYAR 4: MENEBAK WARNA (UI BARU ALA TARGET) ---
  Widget _buildGuess(ColorMatchController controller) {
    // KITA HAPUS DEKLARASI targetColor DI SINI, PINDAHKAN KE DALAM Obx
    
    return Column(
      children: [
        // A. BAGIAN ATAS pudar
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            "Match the sliders to the target color!", 
            style: TextStyle(color: Colors.white54, fontSize: 16)
          ),
        ),
        
        // B. AREA FOTO FULL (Area preview di bagian atas)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Lapisan 1: Kotak Warna User besar di bagian atas
                Expanded(
                  // --- PERBAIKAN 1: BUNGKUS DENGAN Obx ---
                  child: Obx(() {
                    // --- PERBAIKAN 2: GUNAKAN userColor, BUKAN targetColor ---
                    Color userColor = HSLColor.fromAHSL(
                      1.0, 
                      controller.userHue.value, 
                      controller.userSat.value / 100, 
                      controller.userLight.value / 100
                    ).toColor();

                    return Container(
                      decoration: BoxDecoration(
                        color: userColor, // Sekarang menggunakan warna dari slider
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12, width: 1)
                      ),
                    );
                  }),
                ),
                
                // Lapisan 2: Label Warna Slider pudar di bawahnya
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "YOUR COLOR", 
                    style: TextStyle(color: Colors.white60, fontSize: 14, letterSpacing: 1.2)
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // C. PANEL BAWAH (Otomatis menyesuaikan tinggi, TANPA SCROLL)
        Container(
          color: const Color(0xFF13151D), 
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ambil ruang vertikal seminimal mungkin
            children: [
              // Padding untuk membungkus ketiga slider
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    // 3 Slider horizontal
                    _buildHorizontalSliderRow('Hue', controller.userHue, 0, 360, const Color(0xFF4FC3F7), 1),
                    _buildHorizontalSliderRow('Saturation', controller.userSat, 0, 100, Colors.white60, 1),
                    _buildHorizontalSliderRow('Lightness', controller.userLight, 0, 100, Colors.white60, 1),
                  ],
                ),
              ),
              
              // Tombol Tebak Warna dengan GAP di bawah dan sudut membulat
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54, 
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7), // Warna biru
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), 
                        ),
                      ),
                      onPressed: controller.submitGuess,
                      child: const Text("Guess Color", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  // --- LAYAR 5: HASIL RONDE ---
  Widget _buildResult(ColorMatchController controller) {
    Color targetColor = HSLColor.fromAHSL(1.0, controller.targetHue.value, controller.targetSat.value / 100, controller.targetLight.value / 100).toColor();
    Color userColor = HSLColor.fromAHSL(1.0, controller.userHue.value, controller.userSat.value / 100, controller.userLight.value / 100).toColor();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("RESULT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorBox("Target Color", targetColor),
              _colorBox("Your Guess", userColor),
            ],
          ),
          const SizedBox(height: 40),
          Text("Accuracy: ${controller.lastAccuracy.value.toStringAsFixed(1)}%", 
            style: TextStyle(color: controller.lastAccuracy.value > 90 ? Colors.greenAccent : Colors.orange, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: controller.nextRound, 
            child: Text(controller.round.value < 4 ? "Next Round" : "View Final Score")
          )
        ],
      ),
    );
  }

  Widget _colorBox(String label, Color color) {
    return Column(
      children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  // --- LAYAR 6: SKOR FINAL ---
  Widget _buildFinalScore(ColorMatchController controller) {
    double finalAvg = controller.totalScore.value / 4;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text("Complete!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("Final Average:", style: TextStyle(color: Colors.white70, fontSize: 18)),
          Text("${finalAvg.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: controller.backToMenu, child: const Text("Back to Menu")),
        ],
      ),
    );
  }
}