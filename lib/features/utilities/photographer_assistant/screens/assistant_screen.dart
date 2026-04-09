import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        title: const Text('Photographer Assistant', style: TextStyle(color: Colors.white60, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() => Column(
        children: [
          // BAGIAN ATAS: Info Golden Hour
          _buildSunHeader(controller),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("SPOT FOTO ESTETIK TERDEKAT", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            ),
          ),

          // BAGIAN BAWAH: Daftar Spot
          Expanded(
            child: controller.nearbySpots.isEmpty 
              ? _buildEmptyState(controller)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.nearbySpots.length,
                  itemBuilder: (context, index) {
                    var spot = controller.nearbySpots[index];
                    return _buildSpotCard(spot);
                  },
                ),
          ),

          // Tombol Lacak di bawah
          _buildActionButton(controller),
        ],
      )),
    );
  }

  Widget _buildSunHeader(AssistantController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.2), Colors.blue.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _sunInfo("Sunrise", controller.sunrise.value, Icons.wb_twilight),
          const VerticalDivider(color: Colors.white12),
          _sunInfo("Sunset", controller.sunset.value, Icons.wb_sunny_rounded),
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

  Widget _buildSpotCard(dynamic spot) {
    return Card(
      color: const Color(0xFF13151D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.place, color: Colors.blueAccent)),
        title: Text(spot['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(spot['vicinity'] ?? 'Alamat tidak tersedia', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text("${spot['rating'] ?? 'N/A'}", style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AssistantController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 60, color: Colors.white10),
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
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text("CARI SPOT & WAKTU TERBAIK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}