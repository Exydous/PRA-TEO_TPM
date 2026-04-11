import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/preset_store_controller.dart';

class PresetStoreScreen extends StatelessWidget {
  const PresetStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi Controller
    final controller = Get.put(PresetStoreController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Premium Presets', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Dropdown Pilihan Mata Uang
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => DropdownButton<String>(
                  value: controller.selectedCurrency.value,
                  dropdownColor: Colors.grey[900],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  underline: const SizedBox(), // Hilangkan garis bawah default
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.changeCurrency(newValue);
                    }
                  },
                  items: controller.availableCurrencies
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                )),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tingkatkan Kualitas Fotomu",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Beli preset eksklusif dari fotografer kelas dunia.",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Grid Produk
            Expanded(
              child: Obx(() => GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7, // Mengatur tinggi card (lebih tinggi dari lebarnya)
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: controller.dummyPresets.length,
                itemBuilder: (context, index) {
                  final preset = controller.dummyPresets[index];
                  return _buildPresetCard(controller, preset);
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(PresetStoreController controller, PresetItem preset) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mockup Thumbnail Image (Kotak Atas)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(int.parse(preset.colorTheme)),
                    Colors.black,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white54, size: 40),
              ),
            ),
          ),
          
          // Info Teks (Kotak Bawah)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${preset.photographer}',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                      ),
                    ],
                  ),
                  
                  // Harga dan Tombol Beli
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- DIMODIFIKASI: Dibungkus Obx agar reaktif ---
                      Obx(() => Text( 
                        controller.getConvertedPrice(preset.basePriceUSD),
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      )),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => controller.buyPreset(preset),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // Sesuaikan dengan AppColors.primary jika ada
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}