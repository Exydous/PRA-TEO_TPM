import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Model Data untuk Preset
class PresetItem {
  final String id;
  final String name;
  final String photographer;
  final double basePriceUSD; // Harga dasar dalam USD
  final String colorTheme; // Untuk warna kotak mockup

  PresetItem({
    required this.id,
    required this.name,
    required this.photographer,
    required this.basePriceUSD,
    required this.colorTheme,
  });
}

class PresetStoreController extends GetxController {
  // Mata uang yang dipilih saat ini
  var selectedCurrency = 'IDR'.obs;
  final List<String> availableCurrencies = ['IDR', 'USD', 'EUR'];

  // Rate konversi statis (Mockup API)
  // Nanti ini bisa diganti dengan respons dari FreeCurrency API
  final double rateUSD = 1.0;
  final double rateIDR = 15800.0; // 1 USD = 15.800 IDR
  final double rateEUR = 0.92;    // 1 USD = 0.92 EUR

  // Data Dummy Preset Premium
  final RxList<PresetItem> dummyPresets = <PresetItem>[
    PresetItem(id: '1', name: 'Cinematic Teal & Orange', photographer: 'Peter McKinnon', basePriceUSD: 15.0, colorTheme: '0xFF004D40'),
    PresetItem(id: '2', name: 'Moody Moody Film', photographer: 'Chris Hau', basePriceUSD: 12.50, colorTheme: '0xFF3E2723'),
    PresetItem(id: '3', name: 'Tokyo Neon Vibes', photographer: 'Trey Ratcliff', basePriceUSD: 18.0, colorTheme: '0xFF4A148C'),
    PresetItem(id: '4', name: 'Clean Minimalist', photographer: 'Lizzie Peirce', basePriceUSD: 9.99, colorTheme: '0xFFCFD8DC'),
    PresetItem(id: '5', name: 'Vintage Kodak 400', photographer: 'Willem Verbeeck', basePriceUSD: 14.0, colorTheme: '0xFFF57F17'),
    PresetItem(id: '6', name: 'B&W Timeless', photographer: 'Alan Schaller', basePriceUSD: 11.0, colorTheme: '0xFF212121'),
  ].obs;

  // Fungsi dinamis untuk menghitung harga sesuai mata uang yang dipilih
  String getConvertedPrice(double basePrice) {
    switch (selectedCurrency.value) {
      case 'IDR':
        double price = basePrice * rateIDR;
        // Format ke ribuan ala Indonesia
        return 'Rp ${price.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';
      case 'EUR':
        double price = basePrice * rateEUR;
        return '€${price.toStringAsFixed(2)}';
      case 'USD':
      default:
        return '\$${basePrice.toStringAsFixed(2)}';
    }
  }

  void changeCurrency(String currency) {
    selectedCurrency.value = currency;
  }

  void buyPreset(PresetItem preset) {
    // Aksi ketika tombol beli ditekan
    Get.snackbar(
      '🛒 Pembelian Berhasil',
      'Preset "${preset.name}" telah ditambahkan ke galerimu!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 3),
    );
  }
}