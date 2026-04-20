import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tugas_akhir/features/editor/controllers/editor_controller.dart';
import '../controllers/preset_store_controller.dart';

class PresetStoreScreen extends StatelessWidget {
  const PresetStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi Controller
    final controller = Get.put(PresetStoreController());
    // final editorController = Get.put(EditorController()); // Memastikan EditorController aktif

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
                  underline: const SizedBox(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      // Panggil updateCurrency yang langsung menembak API kurs
                      controller.updateCurrency(newValue);
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
            
            // Grid Produk dari Supabase
            Expanded(
              child: Obx(() {
                // 1. Tampilkan loading jika data Supabase masih ditarik
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                // 2. Tampilkan pesan jika tabel di database kosong
                if (controller.presets.isEmpty) {
                  return const Center(
                    child: Text("Belum ada preset tersedia saat ini.", style: TextStyle(color: Colors.white54))
                  );
                }

                // 3. Tampilkan Grid jika data berhasil didapat
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Disesuaikan karena butuh ruang untuk gambar web
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: controller.presets.length,
                  itemBuilder: (context, index) {
                    // Tipe datanya sekarang Map, bukan PresetItem lagi
                    final preset = controller.presets[index];
                    return _buildPresetCard(controller, preset);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Parameter diubah untuk menerima tipe data Map (JSON dari Supabase)
  Widget _buildPresetCard(PresetStoreController controller, Map<String, dynamic> preset) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Asli dari Link Web
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                preset['thumbnail_url'] ?? '', 
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container( 
                  color: Colors.black45,
                  child: const Icon(Icons.broken_image, color: Colors.white54, size: 40), 
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2));
                },
              ),
            ),
          ),
          
          // Info Teks (Kotak Bawah)
          Expanded(
            flex: 5,
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
                        preset['name'] ?? 'Unknown Preset',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${preset['author'] ?? 'Admin'}',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                      ),
                    ],
                  ),
                  
                  // Harga dan Tombol Beli / Owned
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loading kecil saat API FreeCurrency sedang menghitung kurs
                      Obx(() => controller.isCurrencyLoading.value 
                        ? const SizedBox(
                            height: 16, width: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)
                          )
                        : Text( 
                            controller.getConvertedPrice((preset['price_usd'] as num?)?.toDouble() ?? 0.0),
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          )
                      ),
                      const SizedBox(height: 8),
                      
                      // --- LOGIKA TOMBOL BERUBAH (BELI vs OWNED) ---
                      Obx(() {
                        // Mengecek apakah ID preset ini sudah ada di daftar ownedPresets
                        final EditorController editorController = Get.find<EditorController>();
                        bool isOwned = editorController.ownedPresets.any((p) => p['id'] == preset['id']);

                        if (isOwned) {
                          // Tampilan jika SUDAH DIBELI
                          return SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.snackbar('Tersedia', 'Preset ini sudah ada di Editor-mu!', backgroundColor: Colors.blueGrey.shade900, colorText: Colors.white);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white54,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.check_circle, size: 14),
                              label: const Text('Owned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          );
                        } else {
                          // Tampilan jika BELUM DIBELI
                          return SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => controller.buyPreset(preset),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, 
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          );
                        }
                      }),
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