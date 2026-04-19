import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/editor_controller.dart';
// IMPORT CONTROLLER COLOR TRANSFER (Sesuaikan path jika perlu)
import '../../ai_assistant/controllers/color_transfer_controller.dart'; 

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorController controller = Get.find<EditorController>();
    // Daftarkan Color Transfer Controller ke layar ini
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
          onPressed: controller.cancelEditing, // Akan memicu saveToWorkspace (Draft)
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
          IconButton(icon: const Icon(Icons.undo, color: Colors.white70), onPressed: controller.undo),
          IconButton(icon: const Icon(Icons.redo, color: Colors.white70), onPressed: controller.redo),
          
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent), 
            tooltip: 'Reset Semua',
            onPressed: () => controller.resetEffects(fromSensor: false),
          ),
          
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary), 
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
                            child: Text("Gagal memuat gambar", style: TextStyle(color: Colors.white54)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // --- 2. FITUR BARU: REFERENCE COLOR TRANSFER ---
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
                        Text('Transfer Gaya Warna', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Tiru warna dari foto/scene film lain', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        child: const Text('Pilih Foto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  // --- HELPER WIDGETS ---
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
        const Text("Pilih alat untuk rasio dan rotasi foto", style: TextStyle(color: Colors.white54)),
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
            // --- SLIDER TINT BARU DITAMBAHKAN DI SINI ---
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
}