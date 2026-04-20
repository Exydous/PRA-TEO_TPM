import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tugas_akhir/features/editor/controllers/editor_controller.dart';
import '../../../../services/currency_service.dart'; // Pastikan path ini sesuai

class PresetStoreController extends GetxController {
  // Inisialisasi layanan Cloud & API
  final supabase = Supabase.instance.client;
  final CurrencyService _currencyService = CurrencyService();
  
  // Data dinamis dari Cloud Supabase
  var presets = <Map<String, dynamic>>[].obs;
  
  // Status Loading
  var isLoading = true.obs;
  var isCurrencyLoading = false.obs;

  // Mata uang yang dipilih
  var selectedCurrency = 'IDR'.obs;
  final List<String> availableCurrencies = ['IDR', 'USD', 'EUR'];
  
  // Rate dinamis dari API
  var exchangeRate = 15500.0.obs; 

  @override
  void onInit() {
    super.onInit();
    fetchPresets(); 
    updateCurrency('IDR'); 
  }

  // --- 1. AMBIL DATA DARI SUPABASE ---
  Future<void> fetchPresets() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('presets')
          .select()
          .order('created_at', ascending: false);
      
      presets.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetching Presets: $e");
      Get.snackbar(
        "Kesalahan Jaringan", 
        "Gagal memuat preset. Pastikan internetmu stabil.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- 2. AMBIL KURS DARI FREECURRENCY API ---
  Future<void> updateCurrency(String currencyCode) async {
    isCurrencyLoading.value = true;
    selectedCurrency.value = currencyCode;
    
    if (currencyCode == 'USD') {
      exchangeRate.value = 1.0;
    } else {
      exchangeRate.value = await _currencyService.getExchangeRate(currencyCode);
    }
    
    isCurrencyLoading.value = false;
  }

  // --- 3. FORMAT HARGA DINAMIS ---
  String getConvertedPrice(double basePriceUsd) {
    double convertedPrice = basePriceUsd * exchangeRate.value;
    
    if (selectedCurrency.value == 'IDR') {
      return "Rp ${convertedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
    } else if (selectedCurrency.value == 'EUR') {
      return "€${convertedPrice.toStringAsFixed(2)}";
    }
    return "\$${convertedPrice.toStringAsFixed(2)}";
  }

  // --- 4. PEMBELIAN & SIMPAN KE DATABASE ---
  Future<void> buyPreset(Map<String, dynamic> preset) async {
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      Get.snackbar('Gagal', 'Kamu harus login terlebih dahulu.');
      return;
    }

    try {
      // 1. Catat pembelian ke tabel user_presets
      await supabase.from('user_presets').insert({
        'user_id': user.id,
        'preset_id': preset['id'],
      });

      // 2. Berikan notifikasi sukses
      Get.snackbar(
        '🛒 Berhasil!',
        'Preset "${preset['name']}" telah ditambahkan ke koleksimu.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // 3. SECARA INSTAN tambahkan ke memori EditorController agar UI langsung berubah
      if (Get.isRegistered<EditorController>()) {
        Get.find<EditorController>().ownedPresets.insert(0, preset);
      }

    } catch (e) {
      // Jika terjadi error (Biasanya karena constraint UNIQUE: User sudah punya preset ini)
      Get.snackbar(
        'Info',
        'Kamu sudah memiliki preset "${preset['name']}" di koleksimu.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
}