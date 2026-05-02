import 'dart:async'; // [BARU] Wajib ditambahkan untuk menjalankan Timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/editor_controller.dart';
import '../../ai_assistant/controllers/color_transfer_controller.dart'; 

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorController controller = Get.find<EditorController>();
    final ColorTransferController transferCtrl = Get.put(ColorTransferController());

    if (controller.selectedImage.value == null) {
      Future.microtask(() => Get.back());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: controller.cancelEditing, 
        ),
        
        title: Row(
          children: [
            const Text('Editor', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 8),
            Obx(() {
              bool isDark = controller.luxValue.value < 15;
              return Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny,
                color: isDark ? Colors.amber : Colors.yellow,
                size: 16,
              );
            }),
          ],
        ),
        
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Colors.white70), onPressed: controller.undo, tooltip: 'UNDO'),
          IconButton(icon: const Icon(Icons.redo, color: Colors.white70), onPressed: controller.redo, tooltip: 'REDO'),
          
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent), 
            tooltip: 'Reset All Changes',
            onPressed: () => controller.resetEffects(fromSensor: false),
          ),
          
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            tooltip: 'Save to Gallery',
            onPressed: controller.saveToGallery, 
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. AREA FOTO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() {
                  final imageFile = controller.selectedImage.value;
                  if (imageFile == null) return const SizedBox.shrink(); 

                  return Center(
                    child: RepaintBoundary(
                      key: controller.exportKey, 
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(controller.combinedColorMatrix),
                        child: Image.file(
                          imageFile, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text("Failed to load image", style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // --- 2. FITUR REFERENCE COLOR TRANSFER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A), 
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                  bottom: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.palette, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transfer Color Style', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Copy colors from other photos/movies', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Obx(() => transferCtrl.isProcessing.value
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                      )
                    : ElevatedButton(
                        onPressed: transferCtrl.pickReferenceAndTransfer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Select Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                  ),
                ],
              ),
            ),

            // 3. PANEL BAWAH (SLIDER & MENU)
            Obx(() => Container(
                  height: 260, 
                  color: const Color(0xFF1A1A1A), 
                  child: Column(
                    children: [
                      Expanded(
                        child: controller.currentMode.value == EditorMode.crop
                            ? _buildCropPanel()
                            : _buildEditPanel(controller),
                      ),
                      
                      // BOTTOM NAVIGATION UTAMA
                      Container(
                        height: 60,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _mainToolButton(
                              icon: Icons.crop_rotate,
                              label: 'Crop',
                              isActive: controller.currentMode.value == EditorMode.crop,
                              onTap: () => controller.currentMode.value = EditorMode.crop,
                            ),
                            _mainToolButton(
                              icon: Icons.tune,
                              label: 'Edit',
                              isActive: controller.currentMode.value == EditorMode.edit,
                              onTap: () => controller.currentMode.value = EditorMode.edit,
                            ),
                            _mainToolButton(
                              icon: Icons.auto_awesome,
                              label: 'My Presets',
                              isActive: false, 
                              onTap: () => _showPresetsBottomSheet(context, controller),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                
          ],
        ),
      ),
    );
  }

  Widget _mainToolButton({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? AppColors.primary : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCropPanel() {
    final EditorController controller = Get.find<EditorController>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Select tool for aspect ratio and rotation", style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _iconButton(Icons.aspect_ratio, 'Aspect', controller.openCropTool),
            _iconButton(Icons.rotate_90_degrees_ccw, 'Rotate', controller.openCropTool),
          ],
        )
      ],
    );
  }
  
  Widget _iconButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPanel(EditorController controller) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildActiveSliders(controller),
          ),
        ),
        
        Container(
          height: 50,
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _editSubMenuButton(controller, EditSubMenu.light, Icons.wb_sunny_outlined, 'Light'),
              _editSubMenuButton(controller, EditSubMenu.color, Icons.color_lens_outlined, 'Color'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editSubMenuButton(EditorController controller, EditSubMenu menuType, IconData icon, String label) {
    bool isActive = controller.currentSubMenu.value == menuType;
    return InkWell(
      onTap: () => controller.currentSubMenu.value = menuType,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? Colors.white : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSliders(EditorController controller) {
    switch (controller.currentSubMenu.value) {
      case EditSubMenu.light:
        return Column(
          children: [
            _buildSliderRow('Exposure', controller.exposure, -100, 100, controller: controller),
            _buildSliderRow('Contrast', controller.contrast, -100, 100, controller: controller),
          ],
        );
      case EditSubMenu.color:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    controller.isBlackAndWhite.toggle();
                    controller.saveState(); 
                  }, 
                  child: Obx(() => Text(controller.isBlackAndWhite.value ? 'B&W (On)' : 'B&W (Off)'))
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderRow('Temp', controller.temperature, -100, 100, controller: controller),
            _buildSliderRow('Tint', controller.tint, -100, 100, controller: controller),
            _buildSliderRow('Saturation', controller.saturation, -100, 100, controller: controller),
          ],
        );
    }
  }

  Widget _buildSliderRow(String label, RxDouble rxValue, double min, double max, {String suffix = '', required EditorController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: rxValue.value,
                min: min,
                max: max,
                onChanged: (val) => rxValue.value = val, 
                onChangeEnd: (val) => controller.saveState(), 
              ),
            ),
          ),
          SizedBox(
            width: 45, 
            child: Text(
              '${rxValue.value.toInt()}$suffix', 
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI BOTTOM SHEET MY PRESETS ---
  void _showPresetsBottomSheet(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13151D),
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea( 
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), 
            height: 240, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Presets',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    if (controller.isPresetsLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    if (controller.ownedPresets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sentiment_dissatisfied, color: Colors.white38, size: 30),
                            const SizedBox(height: 8),
                            const Text(
                              "Collections Empty. Get them from the Store!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.ownedPresets.length,
                      itemBuilder: (context, index) {
                        final preset = controller.ownedPresets[index];
                        // [BARU] Mengecek apakah ada timer untuk preset ini
                        bool hasTimer = preset['expires_at'] != null;

                        return GestureDetector(
                          onTap: () {
                            controller.applyPreset(preset);
                            // Get.back(); // [PENTING] HAPUS ATAU JADIKAN KOMENTAR BARIS INI!
                            // Kenapa? Agar saat diklik, panel preset tidak langsung tertutup. 
                            // Jadi Capt bisa melihat efek glowing-nya menyala dan bisa langsung klik preset lain untuk membandingkan warna.
                          },
                          child: Obx(() {
                            // [BARU] Cek apakah preset ini adalah preset yang sedang aktif
                            bool isActive = controller.activePresetName.value == preset['name'];
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300), // Efek nyala lampu mulus
                              width: 110, 
                              margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8), // Tambah margin agar glowing tidak terpotong
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C24),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  // Jika aktif, border ikut warna utama. Jika tidak, kembali ke aturan awal (orange/putih)
                                  color: isActive 
                                      ? AppColors.primary 
                                      : (hasTimer ? Colors.orange.withOpacity(0.5) : Colors.white12), 
                                  width: isActive ? 2 : (hasTimer ? 1.5 : 1)
                                ),
                                // [BARU] INI DIA MESIN GLOWING-NYA!
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.6), // Warna cahaya
                                          blurRadius: 15, // Seberapa menyebar cahayanya
                                          spreadRadius: 2, // Ketebalan cahaya
                                          offset: const Offset(0, 0), // Cahaya pas di tengah
                                        )
                                      ]
                                    : [], // Jika tidak aktif, bayangan hilang
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), // Disesuaikan sedikit
                                          child: Image.network(
                                            preset['thumbnail_url'] ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image, color: Colors.white54),
                                          ),
                                        ),
                                        if (hasTimer)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: PresetTimerBadge(expiresAt: preset['expires_at']),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                                    child: Text(
                                      preset['name'] ?? 'Preset',
                                      style: TextStyle(
                                        // Warna teks juga ikut menyala jika aktif
                                        color: isActive ? AppColors.primary : Colors.white, 
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- [BARU] WIDGET TIMER KOPASAN DARI PROFIL ---
class PresetTimerBadge extends StatefulWidget {
  final String expiresAt;
  const PresetTimerBadge({super.key, required this.expiresAt});

  @override
  State<PresetTimerBadge> createState() => _PresetTimerBadgeState();
}

class _PresetTimerBadgeState extends State<PresetTimerBadge> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateTimeLeft();
      }
    });
  }

  void _calculateTimeLeft() {
    final expiry = DateTime.parse(widget.expiresAt).toLocal();
    final now = DateTime.now();
    setState(() {
      _timeLeft = expiry.isAfter(now) ? expiry.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(8)),
        ),
        child: const Text('Habis', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      );
    }
    
    String minutes = _timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = _timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade800.withOpacity(0.9),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 10),
          const SizedBox(width: 2),
          Text('$minutes:$seconds', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}