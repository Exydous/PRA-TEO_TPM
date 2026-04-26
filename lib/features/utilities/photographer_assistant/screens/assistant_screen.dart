import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
          
          // Pemilih Radius (5, 10, 15 KM)
          _buildRadiusSelector(controller),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("PETA SPOT FOTO", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            ),
          ),

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

  Widget _buildRadiusSelector(AssistantController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: controller.radiusOptions.map((radius) {
          return Obx(() => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text("${radius.toInt()} KM"),
              selected: controller.selectedRadius.value == radius,
              selectedColor: Colors.blueAccent,
              backgroundColor: const Color(0xFF1A1C24),
              labelStyle: TextStyle(
                color: controller.selectedRadius.value == radius ? Colors.white : Colors.white54, 
                fontWeight: FontWeight.bold
              ),
              onSelected: (selected) {
                if (selected) {
                  controller.selectedRadius.value = radius;
                  if (controller.userLat.value != 0.0) controller.findBestSetup(); 
                }
              },
            ),
          ));
        }).toList(),
      ),
    );
  }

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
            initialZoom: 13.0, 
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            
            // [BARU] LAYER UNTUK MENGGAMBAR GARIS RUTE
            Obx(() => PolylineLayer(
              polylines: [
                if (controller.routePoints.isNotEmpty)
                  Polyline(
                    points: controller.routePoints.toList(), // Solusi penambahan .toList()
                    color: Colors.blueAccent,
                    strokeWidth: 5.0,
                  ),
              ],
            )),

            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(controller.userLat.value, controller.userLon.value),
                  width: 40, height: 40,
                  child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
                ),
                ...controller.nearbySpots.map((spot) {
                  return Marker(
                    point: LatLng(spot['lat'], spot['lon']),
                    width: 50, height: 50,
                    child: GestureDetector(
                      onTap: () => _showSpotDetail(spot, controller), // Kirim controller ke fungsi
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

  void _showSpotDetail(Map<String, dynamic> spot, AssistantController controller) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text((spot['category'] ?? 'General').toString().toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text("${spot['rating'] ?? '0.0'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(spot['name'] ?? 'Spot Foto', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // [DIUBAH] Tombol sekarang memanggil fungsi gambar rute
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Get.back(); // Tutup bottom sheet
                  controller.getRouteToSpot(spot['lat'], spot['lon']); // Panggil rute di dalam peta
                },
                icon: const Icon(Icons.route),
                label: const Text("LIHAT RUTE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

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
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    controller.selectedTimeZone.value = newValue;
                    controller.updateDisplayedTime(); 
                  }
                },
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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