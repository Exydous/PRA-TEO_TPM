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
      backgroundColor: Colors.black, // warna background utilities
      appBar: AppBar(
        title: const Text('Utilities', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, // warna background app bar
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            
            // --- 1. KOTAK MENU UNTUK GAME TEBAK WARNA ---
            Card(
              color: const Color(0xFF1A1A1A), // warna backround color match
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2), // warna background ikon color match
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.palette, color: Colors.blueAccent), // warna ikon color match
                ),
                title: const Text(
                  'Color Match', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18) // warna judul color match
                ),
                subtitle: const Text(
                  'Uji kepekaan insting warnamu!', 
                  style: TextStyle(color: Colors.white70) // warna teks deskripsi color match
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54), // warna ikon panah color match
                onTap: () {
                  Get.to(() => const ColorMatchScreen());
                },
              ),
            ),
            
            const SizedBox(height: 12), // Jarak antar kotak

            // --- 2. KOTAK MENU UNTUK PHOTOGRAPHER ASSISTANT ---
            Card(
              color: const Color(0xFF1A1A1A), // warna background photographer assistant
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), shape: BoxShape.circle), // warna background ikon photographer assistant
                  child: const Icon(Icons.auto_awesome, color: Colors.orangeAccent), // warna ikon photographer assistant
                ),
                title: const Text(
                  'Photographer Assistant', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18) // warna judul photographer assistant
                ),
                subtitle: const Text(
                  'Cek Golden Hour & Spot foto terdekat', 
                  style: TextStyle(color: Colors.white70) // warna teks deskripsi photographer assistant
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54), // warna ikon panah photographer assistant
                onTap: () => Get.to(() => const AssistantScreen()),
              ),
            ),

            const SizedBox(height: 12), // Jarak antar kotak

            // --- 3. DITAMBAHKAN: KOTAK MENU UNTUK PRESET STORE ---
            Card(
              color: const Color(0xFF1A1A1A), // warna background preset store
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle), // warna background ikon preset store
                  child: const Icon(Icons.storefront, color: Colors.purpleAccent), // warna Ikon Toko
                ),
                title: const Text(
                  'Preset Store', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18) // warna judul preset store
                ),
                subtitle: const Text(
                  'Beli preset eksklusif & konversi harga', 
                  style: TextStyle(color: Colors.white70) // warna teks deskripsi preset store
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54), // warna ikon panah preset store
                onTap: () => Get.to(() => const PresetStoreScreen()),
              ),
            ),

          ],
        ),
      ),
    );
  }
}