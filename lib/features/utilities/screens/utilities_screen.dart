import 'package:flutter/material.dart';
import 'package:get/get.dart';
// PENTING: Sesuaikan path import ini jika ada error garis merah
import 'color_match/screens/color_match_screen.dart'; 
import '../photographer_assistant/screens/assistant_screen.dart';
// --- DITAMBAHKAN: Import untuk Preset Store ---
import '../preset_store/screens/preset_store_screen.dart'; 

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Utilities', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            
            // --- 1. KOTAK MENU UNTUK GAME TEBAK WARNA ---
            Card(
              color: const Color(0xFF1A1A1A), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.palette, color: Colors.blueAccent),
                ),
                title: const Text(
                  'Color Match', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                ),
                subtitle: const Text(
                  'Uji kepekaan insting warnamu!', 
                  style: TextStyle(color: Colors.white70)
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  Get.to(() => const ColorMatchScreen());
                },
              ),
            ),
            
            const SizedBox(height: 12), // Jarak antar kotak

            // --- 2. KOTAK MENU UNTUK PHOTOGRAPHER ASSISTANT ---
            Card(
              color: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                ),
                title: const Text(
                  'Photographer Assistant', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                ),
                subtitle: const Text(
                  'Cek Golden Hour & Spot foto terdekat', 
                  style: TextStyle(color: Colors.white70)
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Get.to(() => const AssistantScreen()),
              ),
            ),

            const SizedBox(height: 12), // Jarak antar kotak

            // --- 3. DITAMBAHKAN: KOTAK MENU UNTUK PRESET STORE ---
            Card(
              color: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.storefront, color: Colors.purpleAccent), // Ikon Toko
                ),
                title: const Text(
                  'Preset Store', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                ),
                subtitle: const Text(
                  'Beli preset eksklusif & konversi harga', 
                  style: TextStyle(color: Colors.white70)
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Get.to(() => const PresetStoreScreen()),
              ),
            ),

          ],
        ),
      ),
    );
  }
}