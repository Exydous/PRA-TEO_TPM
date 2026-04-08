import 'package:flutter/material.dart';
import 'package:get/get.dart';
// PENTING: Sesuaikan path import ini jika ada error garis merah
import 'color_match/screens/color_match_screen.dart'; 

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
            const Text(
              "Alat & Permainan",
              style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // --- KOTAK MENU UNTUK GAME TEBAK WARNA ---
            Card(
              color: const Color(0xFF1A1A1A), // Warna kotak abu-abu gelap
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
                  // Membuka layar game saat diklik menggunakan GetX
                  Get.to(() => const ColorMatchScreen());
                },
              ),
            ),
            
            // Nanti jika ada fitur utility lain (seperti Golden Hour), bisa ditambahkan Card baru di bawah sini
          ],
        ),
      ),
    );
  }
}