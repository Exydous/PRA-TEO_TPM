import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/assistant_controller.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssistantController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0B0F),
        title: const Text('Photographer Assistant', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() => Column(
        children: [
          _buildSunHeader(controller),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("PETA SPOT FOTO", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            ),
          ),

          // --- AREA PETA INTERAKTIF ---
          Expanded(
            child: controller.userLat.value == 0.0 
              ? _buildEmptyState(controller)
              : _buildInteractiveMap(controller),
          ),

          _buildActionButton(controller),
        ],
      )),
    );
  }

  // --- WIDGET PETA DARI FLUTTER_MAP ---
  Widget _buildInteractiveMap(AssistantController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(controller.userLat.value, controller.userLon.value),
            initialZoom: 13.0, // Zoom level kota
          ),
          children: [
            // Layer Peta Dasar (Dark Mode OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            
            // Layer Pin/Marker
            MarkerLayer(
              markers: [
                // 1. Pin Lokasi User (Warna Biru)
                Marker(
                  point: LatLng(controller.userLat.value, controller.userLon.value),
                  width: 40, height: 40,
                  child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                ),
                
                // 2. Pin Spot Foto (Warna Merah)
                ...controller.nearbySpots.map((spot) {
                  return Marker(
                    point: LatLng(spot['lat'], spot['lon']),
                    width: 50, height: 50,
                    child: GestureDetector(
                      // Munculkan pop-up saat pin ditekan
                      onTap: () => _showSpotDetail(spot),
                      child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET SAAT PIN PETA DIKLIK ---
  void _showSpotDetail(Map<String, dynamic> spot) {
    double distanceInMeters = (spot['distance'] as num?)?.toDouble() ?? 0.0;
    String distanceLabel = distanceInMeters > 1000 
        ? "${(distanceInMeters / 1000).toStringAsFixed(1)} km" 
        : "${distanceInMeters.toInt()} m";

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF13151D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(spot['category'].toString().toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(spot['name'] ?? 'Spot Tersembunyi', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(spot['address'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.directions_walk, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text("Jarak: $distanceLabel", style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tombol Buka Rute Peta
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Get.back(); // Tutup sheet
                  _openMaps(spot['lat'], spot['lon']);
                },
                icon: const Icon(Icons.navigation),
                label: const Text("Mulai Navigasi", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- LOGIKA BUKA GOOGLE MAPS ---
  void _openMaps(double? lat, double? lon) async {
    if (lat == null || lon == null) return;
    
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Gagal", "Tidak dapat membuka aplikasi peta.");
    }
  }

  // --- WIDGET HEADER MATAHARI ---
  Widget _buildSunHeader(AssistantController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.2), Colors.blue.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        children: [
          // 1. Bagian Dropdown Pemilih Zona Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: controller.selectedTimeZone.value,
                dropdownColor: const Color(0xFF13151D),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                underline: const SizedBox(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                items: ['WIB', 'WITA', 'WIT', 'LONDON'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    controller.selectedTimeZone.value = newValue;
                    // BACA INI: Paksa controller menghitung ulang waktu saat zona diganti
                    controller.updateDisplayedTime(); 
                  }
                },
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          
          // 2. Bagian Angka Waktunya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // BACA INI: Menggunakan .value agar UI bereaksi terhadap perubahan
              _sunInfo("Sunrise", controller.displaySunrise.value, Icons.wb_twilight),
              const VerticalDivider(color: Colors.white12),
              _sunInfo("Sunset", controller.displaySunset.value, Icons.wb_sunny_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sunInfo(String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orangeAccent),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(AssistantController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 60, color: Colors.white10),
          const SizedBox(height: 16),
          Text(controller.statusMessage.value, style: const TextStyle(color: Colors.white38), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionButton(AssistantController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: controller.isLoading.value ? null : controller.findBestSetup,
            child: controller.isLoading.value 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text("CARI LOKASI & WAKTU TERBAIK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}