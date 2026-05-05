import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/color_match_controller.dart';

class ColorMatchScreen extends StatelessWidget {
  const ColorMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ColorMatchController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F), // warna background color match
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0F), // warna app bar
        title: const Text(
          'Tebak Warna', 
          style: TextStyle(color: Colors.white60, fontSize: 16) // warna teks 
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white60), // warna ikon back button
        elevation: 0,
      ),
      body: Obx(() {
        switch (controller.currentState.value) {
          case GameState.menu: return _buildMenu(controller);
          case GameState.leaderboard: return _buildLeaderboard(controller);
          case GameState.memorize: return _buildMemorize(controller);
          case GameState.guess: return _buildGuess(controller); 
          case GameState.result: return _buildResult(controller);
          case GameState.finalScore: return _buildFinalScore(controller);
        }
      }),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildHorizontalSliderRow(String label, RxDouble rxVal, double min, double max, Color thumbColor, double step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)) // warna teks label slider
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: thumbColor,
                inactiveTrackColor: Colors.white12, // warna trek slider
                thumbColor: thumbColor,
                overlayColor: thumbColor.withOpacity(0.14),
              ),
              child: Slider(
                value: rxVal.value,
                min: min,
                max: max,
                onChanged: (val) {
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
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), // warna latar belakang nilai slider
            child: Text(
              "${rxVal.value.toInt()}", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16) // warna teks nilai slider
            ),
          ),
        ],
      ),
    );
  }

  // --- LAYAR 1: MENU UTAMA ---
  Widget _buildMenu(ColorMatchController controller) {
    final TextEditingController nameInputCtrl = TextEditingController();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.palette_outlined, size: 80, color: Color(0xFF4FC3F7)), // warna ikon menu utama
            const SizedBox(height: 20),
            const Text("COLOR MATCH", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), // warna judul menu utama
            const Text("GUESS THE COLOR IF YOU CAN!", style: TextStyle(color: Colors.white54, fontSize: 14)), // warna subjudul menu utama
            const SizedBox(height: 40),
            
            Obx(() => Text(
              "Playing as: ${controller.gameUsername.value}",
              style: const TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.w600, fontSize: 16), // warna teks username yang sedang bermain
            )),
            const SizedBox(height: 12),

            TextField(
              controller: nameInputCtrl,
              style: const TextStyle(color: Colors.white), // warna teks input username
              decoration: InputDecoration(
                hintText: "Ganti username game (Opsional)",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13), // warna teks hint
                filled: true,
                fillColor: const Color(0xFF1A1C24), // warna background input username
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)), // warna border input username
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4FC3F7))), // warna border saat input username aktif
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF4FC3F7)), // warna ikon tombol konfirmasi ganti username
                  onPressed: () {
                    controller.updateGameUsername(nameInputCtrl.text);
                    Get.focusScope?.unfocus();
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7), // warna background tombol start game
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () {
                  if (nameInputCtrl.text.isNotEmpty) {
                    controller.updateGameUsername(nameInputCtrl.text);
                  }
                  controller.startSoloGame();
                },
                child: const Text("START GAME", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)), // warna teks tombol start game
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60, // warna teks tombol view leaderboard
              ),
              onPressed: () {
                controller.fetchLeaderboard(); 
                controller.currentState.value = GameState.leaderboard;
              },
              child: const Text("VIEW LEADERBOARD", style: TextStyle(color: Colors.white60)), // warna teks tombol view leaderboard
            ),
          ],
        ),
      ),
    );
  }

  // --- LAYAR 2: LEADERBOARD GLOBAL ---
  Widget _buildLeaderboard(ColorMatchController controller) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text("TOP LEADERBOARD", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), // warna judul leaderboard
          const SizedBox(height: 24),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingLeaderboard.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7))); 
              }
              if (controller.globalLeaderboard.isEmpty) {
                return const Center(child: Text("Belum ada skor", style: TextStyle(color: Colors.white24))); // warna teks saat leaderboard kosong
              }
              return ListView.builder(
                itemCount: controller.globalLeaderboard.length,
                itemBuilder: (context, index) {
                  final data = controller.globalLeaderboard[index];
                  Color rankColor = index == 0 ? Colors.amber : (index == 1 ? Colors.grey : (index == 2 ? Colors.brown : Colors.white24)); // warna ikon dan border untuk peringkat 1-3, peringkat lainnya warna putih dengan opacity rendah
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: index < 3 ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.03), // warna latar belakang untuk peringkat 1-3 lebih terang, peringkat lainnya lebih gelap
                      borderRadius: BorderRadius.circular(12),
                      border: index < 3 ? Border.all(color: rankColor.withOpacity(0.5)) : null,
                    ),
                    child: ListTile(
                      leading: Icon(index < 3 ? Icons.emoji_events : Icons.person_outline, color: rankColor),
                      title: Text(data['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // warna teks username di leaderboard
                      trailing: Text(
                        "${(data['accuracy_score'] as num).toStringAsFixed(1)}%", 
                        style: const TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold) // warna teks skor di leaderboard
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white10), // warna background tombol back to menu di leaderboard
            onPressed: controller.backToMenu, 
            child: const Text("Back to Menu")
          )
        ],
      ),
    );
  }

  // --- LAYAR 3: MENGINGAT WARNA ---
  Widget _buildMemorize(ColorMatchController controller) {
    Color targetColor = HSLColor.fromAHSL(1.0, controller.targetHue.value, controller.targetSat.value / 100, controller.targetLight.value / 100).toColor();
    
    return Container(
      width: double.infinity,
      color: targetColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), // warna latar belakang panel memorisasi
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("ROUND ${controller.round.value}/4", style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 14, fontWeight: FontWeight.bold)), // warna teks ronde saat memorisasi
                const SizedBox(height: 8),
                const Text("MEMORIZE THIS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), // warna teks instruksi saat memorisasi
                Text("${controller.countdown.value}", style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)), // warna teks countdown saat memorisasi
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LAYAR 4: MENEBAK WARNA ---
  Widget _buildGuess(ColorMatchController controller) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text("Match the sliders to the target color!", style: TextStyle(color: Colors.white54, fontSize: 14)), // warna teks instruksi saat menebak warna
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Obx(() {
                    Color userColor = HSLColor.fromAHSL(1.0, controller.userHue.value, controller.userSat.value / 100, controller.userLight.value / 100).toColor();
                    return Container(
                      decoration: BoxDecoration(
                        color: userColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10, width: 2) // warna border kotak tebakan warna
                      ),
                    );
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text("YOUR COLOR", style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 2)), // warna teks label kotak tebakan warna
                ),
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), 
          decoration: const BoxDecoration(
            color: Color(0xFF13151D), // warna latar belakang panel slider
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHorizontalSliderRow('Hue', controller.userHue, 0, 360, const Color(0xFF4FC3F7), 1), // warna slider hue
                _buildHorizontalSliderRow('Saturation', controller.userSat, 0, 100, Colors.white60, 1), // warna slider saturation
                _buildHorizontalSliderRow('Lightness', controller.userLight, 0, 100, Colors.white60, 1), // warna slider lightness
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7), // warna background tombol submit guess
                      foregroundColor: Colors.black, // warna teks tombol submit guess
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.submitGuess,
                    child: const Text("SUBMIT GUESS", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
          const Text("ROUND RESULT", style: TextStyle(color: Colors.white70, fontSize: 16)), // warna teks judul hasil ronde
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorBox("Target", targetColor),
              _colorBox("Your Guess", userColor),
            ],
          ),
          const SizedBox(height: 40),
          Text("${controller.lastAccuracy.value.toStringAsFixed(1)}%", 
            style: TextStyle(color: controller.lastAccuracy.value > 85 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 56, fontWeight: FontWeight.bold) // warna teks skor ronde, hijau jika akurasi di atas 85%, oranye jika di bawah atau sama dengan 85%
          ),
          const Text("ACCURACY", style: TextStyle(color: Colors.white38, letterSpacing: 4)), // warna teks label skor ronde
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: controller.nextRound, 
            child: Text(controller.round.value < 4 ? "Next Round" : "Final Results")
          )
        ],
      ),
    );
  }

  Widget _colorBox(String label, Color color) {
    return Column(
      children: [
        Container(width: 120, height: 120, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12))), // warna border kotak warna di hasil ronde
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white60)), // warna teks label kotak warna di hasil ronde
      ],
    );
  }

  // --- LAYAR 6: SKOR FINAL DENGAN HADIAH PRESET ---
  Widget _buildFinalScore(ColorMatchController controller) {
    double finalAvg = controller.totalScore.value / 4;
    return Center(
      child: SingleChildScrollView( // Ditambahkan agar tidak error jika layar kecil
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, size: 100, color: Colors.amber), // warna ikon skor final
              const SizedBox(height: 24),
              Text(controller.gameUsername.value, style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 22, fontWeight: FontWeight.bold)), // warna teks username di skor final
              const Text("GAME COMPLETE!", style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2)), // warna teks subjudul di skor final
              const SizedBox(height: 30),
              Text("${finalAvg.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)), // warna teks skor final
              const Text("AVERAGE ACCURACY", style: TextStyle(color: Colors.white24, letterSpacing: 2)), // warna teks label skor final
              
              // --- [BARU] WIDGET HADIAH PRESET ---
              Obx(() {
                if (controller.isWonReward.value && controller.wonPresetDetails.isNotEmpty) {
                  final preset = controller.wonPresetDetails;
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1), // warna latar belakang panel hadiah preset
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade700, width: 2), // warna border panel hadiah preset
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "🎉 BONUS PRESET 1 Menit! 🎉", // edit waktu
                              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16) // warna teks judul hadiah preset
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                preset['thumbnail_url'] ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.broken_image, color: Colors.white54, size: 40), // ikon jika gambar preset gagal dimuat, dengan warna ikon
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              preset['name'] ?? 'Premium Preset', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14) // warna teks nama preset di hadiah preset
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Cek Profilmu sekarang!", 
                              style: TextStyle(color: Colors.white70, fontSize: 12) // warna teks instruksi di hadiah preset
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink(); // Jika kalah, bagian ini hilang
              }),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.all(16)), // warna background tombol back to menu di skor final
                  onPressed: controller.backToMenu, 
                  child: const Text("BACK TO MENU")
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}